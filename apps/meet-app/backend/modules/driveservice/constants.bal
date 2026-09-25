// Copyright (c) 2026 WSO2 LLC. (https://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

# client retry configuration for max retry attempts.
public const int RETRY_COUNT = 3;

# client retry configuration for wait interval in seconds.
public const decimal RETRY_INTERVAL = 3.0;

# client retry configuration for interval increment in seconds.
public const float RETRY_BACKOFF_FACTOR = 2.0;

# client retry configuration for maximum wait interval in seconds.
public const decimal RETRY_MAX_INTERVAL = 20.0;

# People per request in grantAccessInBatches. Each batch must finish well inside the Choreo
# gateway's 60-second limit: stage granted roughly 2-4 people a second per share, so 25 takes
# about 10 seconds, leaving room for drive-service's rate-limit backoff on a throttled batch.
const int GRANT_BATCH_SIZE = 25;
