// Copyright (c) 2025, WSO2 LLC. (https://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

# client retry configuration for max retry attempts.
public const int RETRY_COUNT = 3;

# client retry configuration for wait interval in seconds.
public const decimal RETRY_INTERVAL = 3.0;

# client retry configuration for interval increment in seconds.
public const float RETRY_BACKOFF_FACTOR = 2.0;

# client retry configuration for maximum wait interval in seconds.
public const decimal RETRY_MAX_INTERVAL = 20.0;
