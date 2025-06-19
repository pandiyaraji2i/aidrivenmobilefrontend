Prompt for writing unit tests for existing projects:
 
```markdown
# Unit Testing Guidelines for Existing Projects 

## Objective
Write comprehensive unit tests for existing codebase without modifying the core business logic. (Settings Module)

## Key Areas to Test

1. **Table View Interactions**
   - Test valid row selections
   - Test invalid index paths
   - Verify correct string matching
   - Check array bounds and data loading

2. **URL Validations**
   - Test all external links (Privacy Policy, Terms of Service, App Store)
   - Verify HTTPS protocol
   - Check URL validity
   - Validate share functionality URLs

3. **Database Operations**
   - Test data loading from local database
   - Verify data persistence
   - Check data integrity
   - Test empty/null cases

4. **UI Elements**
   - Verify icon existence
   - Test button actions
   - Check label text
   - Validate view hierarchy

## Test Structure
- Use Given-When-Then pattern
- Include setup and teardown
- Follow clear naming conventions
- Document test purpose

## Success Criteria
- Tests should be independent
- No modification to existing logic
- Clear failure messages
- Coverage of edge cases
- Proper error handling

## Common Test Scenarios
- Happy path (success cases)
- Edge cases (boundary conditions)
- Error cases (failure scenarios)
- Invalid input handling
- State management

## Best Practices
- Mock dependencies
- Use clear assertions
- Handle async operations
- Clean up resources
- Document test cases

## Documentation
- Purpose of each test
- Expected behavior
- Test prerequisites
- Known limitations
- Setup requirements
```
