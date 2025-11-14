# `CLAUDE.md` - Julep Backend Service  

## The Golden Rule  
When unsure about implementation details, ALWAYS ask the developer.  

## Project Context  
Julep enables developers to build stateful AI agents using declarative  
workflows.  

## Critical Architecture Decisions  

### Why Temporal?  
We use Temporal for workflow orchestration because:  
1. Workflows can run for days/weeks with perfect reliability  
2. Automatic recovery from any failure point  

### Why PostgreSQL + pgvector?  
1. ACID compliance for workflow state (can't lose user data)  
2. Vector similarity search for agent memory  

### Why TypeSpec?  
Single source of truth for API definitions:  
- OpenAPI specs  
- TypeScript/Python clients  
- Validation schemas  

## Code Style and Patterns  

### Anchor comments  

Add specially formatted comments throughout the codebase, where appropriate, for yourself as inline knowledge that can be easily `grep`ped for.  

### Guidelines:  

- Use `AIDEV-NOTE:`, `AIDEV-TODO:`, or `AIDEV-QUESTION:` (all-caps prefix) for comments aimed at AI and developers.  
- **Important:** Before scanning files, always first try to **grep for existing anchors** `AIDEV-*` in relevant subdirectories.  
- **Update relevant anchors** when modifying associated code.  
- **Do not remove `AIDEV-NOTE`s** without explicit human instruction.  
- Make sure to add relevant anchor comments, whenever a file or piece of code is:  
  * too complex, or  
  * very important, or  
  * confusing, or  
  * could have a bug  

## Domain Glossary (Claude, learn these!)  

- **Agent**: AI entity with memory, tools, and defined behavior  
- **Task**: Workflow definition composed of steps (NOT a Celery task)  
- **Execution**: Running instance of a task  
- **Tool**: Function an agent can call (browser, API, etc.)  
- **Session**: Conversation context with memory  
- **Entry**: Single interaction within a session  

## What AI Must NEVER Do  

1. **Never modify test files** - Tests encode human intent  
2. **Never change API contracts** - Breaks real applications  
3. **Never alter migration files** - Data loss risk  
4. **Never commit secrets** - Use environment variables  
5. **Never assume business logic** - Always ask  
6. **Never remove AIDEV- comments** - They're there for a reason  

Remember: We optimize for maintainability over cleverness.  
When in doubt, choose the boring solution.  
