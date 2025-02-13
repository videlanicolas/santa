/// Copyright 2022 Google Inc. All rights reserved.
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
///    http://www.apache.org/licenses/LICENSE-2.0
///
///    Unless required by applicable law or agreed to in writing, software
///    distributed under the License is distributed on an "AS IS" BASIS,
///    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///    See the License for the specific language governing permissions and
///    limitations under the License.

#include "Source/santad/Metrics.h"

#include <memory>

#import "Source/common/SNTLogging.h"
#import "Source/common/SNTMetricSet.h"
#import "Source/common/SNTXPCMetricServiceInterface.h"
#import "Source/santad/SNTApplicationCoreMetrics.h"

namespace santa::santad {

std::shared_ptr<Metrics> Metrics::Create(uint64_t interval) {
  dispatch_queue_t q = dispatch_queue_create("com.google.santa.santametricsservice.q",
                                             DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL);

  dispatch_source_t timer_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, q);

  MOLXPCConnection *metrics_connection = [SNTXPCMetricServiceInterface configuredConnection];

  std::shared_ptr<Metrics> metrics =
    std::make_shared<Metrics>(metrics_connection, q, timer_source, interval, ^() {
      SNTRegisterCoreMetrics();
      [metrics_connection resume];
    });

  std::weak_ptr<Metrics> weak_metrics(metrics);
  dispatch_source_set_event_handler(metrics->timer_source_, ^{
    std::shared_ptr<Metrics> shared_metrics = weak_metrics.lock();
    if (!shared_metrics) {
      return;
    }

    [[shared_metrics->metrics_connection_ remoteObjectProxy]
      exportForMonitoring:[[SNTMetricSet sharedInstance] export]];
  });

  return metrics;
}

Metrics::Metrics(MOLXPCConnection *metrics_connection, dispatch_queue_t q,
                 dispatch_source_t timer_source, uint64_t interval,
                 void (^run_on_first_start)(void))
    : q_(q),
      timer_source_(timer_source),
      interval_(interval),
      running_(false),
      run_on_first_start_(run_on_first_start) {
  metrics_connection_ = metrics_connection;
  SetInterval(interval_);
}

Metrics::~Metrics() {
  if (!running_) {
    // The timer_source_ must be resumed to ensure it has a proper retain count before being
    // destroyed. Additionally, it should first be cancelled to ensure the timer isn't ever fired
    // (see man page for `dispatch_source_cancel(3)`).
    dispatch_source_cancel(timer_source_);
    dispatch_resume(timer_source_);
  }
}

void Metrics::SetInterval(uint64_t interval) {
  dispatch_sync(q_, ^{
    LOGI(@"Setting metrics interval to %llu (exporting? %s)", interval, running_ ? "YES" : "NO");
    interval_ = interval;
    dispatch_source_set_timer(timer_source_, dispatch_time(DISPATCH_TIME_NOW, 0),
                              interval_ * NSEC_PER_SEC, 250 * NSEC_PER_MSEC);
  });
}

void Metrics::StartPoll() {
  static dispatch_once_t once_token;
  dispatch_once(&once_token, ^{
    run_on_first_start_();
  });

  dispatch_sync(q_, ^{
    if (!running_) {
      LOGI(@"Starting to export metrics every %llu seconds", interval_);
      running_ = true;
      dispatch_resume(timer_source_);
    } else {
      LOGW(@"Attempted to start metrics poll while already started");
    }
  });
}

void Metrics::StopPoll() {
  dispatch_sync(q_, ^{
    if (running_) {
      LOGI(@"Stopping metrics export");
      dispatch_suspend(timer_source_);
      running_ = false;
    } else {
      LOGW(@"Attempted to stop metrics poll while already stopped");
    }
  });
}

}  // namespace santa::santad
