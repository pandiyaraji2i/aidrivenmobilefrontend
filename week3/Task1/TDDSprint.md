# Test Case Writing Guide for OTP Flow


## Test Case Structure
1. **Given-When-Then Format**
   - Given: Initial conditions and test data
   - When: Action being tested
   - Then: Expected outcomes and assertions


## OTP Request Test Cases


### 1. Valid Mobile Number
**Prompt:**
```
Test Case: OTP Request with Valid Mobile Number
Given:
- A valid 10-digit mobile number
- Network is available
- Server is responding


When:
- User enters the mobile number
- OTP request is made to the server


Then:
- Request should be successful
- Response should contain success=true
- Message should indicate OTP sent
- No error should be returned
```


### 2. Invalid Mobile Number
**Prompt:**
```
Test Case: OTP Request with Invalid Mobile Number
Given:
- An invalid mobile number (less than 10 digits)
- Network is available
- Server is responding


When:
- User enters the invalid mobile number
- OTP request is made to the server


Then:
- Request should complete
- Response should contain success=false
- Message should indicate invalid mobile number
- No error should be returned
```


### 3. Network Error
**Prompt:**
```
Test Case: OTP Request with Network Error
Given:
- A valid mobile number
- Network is unavailable
- Server is not reachable


When:
- User enters the mobile number
- OTP request is made to the server


Then:
- Request should fail
- Error should be returned
- Error message should indicate network issue
```


## OTP Verification Test Cases


### 1. Valid OTP
**Prompt:**
```
Test Case: OTP Verification with Valid OTP
Given:
- A valid mobile number
- A valid 6-digit OTP
- Network is available
- Server is responding


When:
- User enters the OTP
- Verification request is made to the server


Then:
- Request should be successful
- Response should contain success=true
- Message should indicate successful verification
- Data should contain token and student information
- No error should be returned
```


### 2. Invalid OTP
**Prompt:**
```
Test Case: OTP Verification with Invalid OTP
Given:
- A valid mobile number
- An invalid OTP (wrong digits)
- Network is available
- Server is responding


When:
- User enters the invalid OTP
- Verification request is made to the server


Then:
- Request should complete
- Response should contain success=false
- Message should indicate invalid OTP
- No error should be returned
```


### 3. Expired OTP
**Prompt:**
```
Test Case: OTP Verification with Expired OTP
Given:
- A valid mobile number
- An expired OTP
- Network is available
- Server is responding


When:
- User enters the expired OTP
- Verification request is made to the server


Then:
- Request should complete
- Response should contain success=false
- Message should indicate OTP expired
- No error should be returned
```


## Multiple Students Test Case
**Prompt:**
```
Test Case: OTP Verification with Multiple Students
Given:
- A valid mobile number
- A valid OTP
- Multiple students associated with the mobile number
- Network is available
- Server is responding


When:
- User enters the OTP
- Verification request is made to the server


Then:
- Request should be successful
- Response should contain success=true
- Data should contain array of students
- Each student should have complete information
- No error should be returned
```


## Token Storage Test Case
**Prompt:**
```
Test Case: Token Storage After Successful Verification
Given:
- A valid mobile number
- A valid OTP
- Successful verification response
- Token is received from server


When:
- OTP verification is successful
- Token is stored in UserDefaults
- User logs out


Then:
- Token should be stored successfully
- Token should be retrievable
- Token should be cleared on logout
- No token should remain after logout
```
