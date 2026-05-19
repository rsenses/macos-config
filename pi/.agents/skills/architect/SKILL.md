---
name: architect
description: Specification design, behavior contracts, and task decomposition.
---

# Architect: Design and Planning

## 1. Specifications (Specs)
Validate requirements before coding. If ambiguous, generate a `Spec / Contract` section in the current session plan.

### Spec Content:
- **Objective**: What we are building and why.
- **Success Criteria**: Specific, testable conditions for task completion.
- **Boundaries**: What is out of scope and what requires confirmation (e.g., DB changes).
- **Assumptions**: List assumptions and ask for confirmation before proceeding.

## 2. Planning and Decomposition
Break work into small, independent, and verifiable tasks.

### Task Rules:
- **Vertical Slicing**: Each task delivers a minimum functional piece (e.g., DB + API + basic UI).
- **Size**: Maximum 5 files per task. If larger, break it down.
- **Checkpoints**: Define validation milestones every 2-3 tasks.

### Task Structure in Plan:
- `[ ] Task N: [Title]`
  - **Description**: Brief what and how.
  - **Acceptance Criteria**: List of behavior checks.
  - **Verification**: Test commands or manual steps to validate.
  - **Files**: List of likely affected files.

## 3. Gated Process
1. **Specify**: Human validates requirements and success criteria.
2. **Plan**: Human validates the technical approach and architecture.
3. **Tasks**: Human validates decomposition and execution order.
4. **Implement**: Only after the above steps are validated.
