# Salesforce CPQ Project: Automation & Governance Engine

This repository contains a professional-grade Apex framework developed for a Salesforce CPQ-enabled environment. The project focuses on high-impact sales automation, discount compliance, and a hybrid manual/automated approval state machine.

## 🚀 Key Features

### 1. Opportunity-to-Quote Automation
- **Logic:** Automatically triggers the creation of a `Quote` record when an `Opportunity` stage transitions to `Proposal/Price Quote`.
- **Smart Pricebook Selection:** - Prioritizes a custom **"Solar Book"** for all sector-specific deals.
    - Includes a dynamic fallback to the **Standard Pricebook** via `Test.getStandardPricebookId()` to ensure 100% uptime during deployments and tests.
- **Data Integrity:** Implements duplicate checks to prevent redundant quote generation.

### 2. Discount Policy & Hard-Cap Enforcement
- **Governance:** Blocks any discount exceeding **50%** at the database level unless explicitly overridden by specific Product Category permissions.
- **Contextual Feedback:** Uses `addError()` to provide real-time, actionable validation messages to Sales Representatives, reducing training overhead.

### 3. Hybrid Approval State Machine (Automated vs. Manual)
- **Status-Driven Logic:** Manages the lifecycle of a Quote through `Draft`, `Submitted`, and `Approved` statuses using a `beforeUpdate` trigger handler.
- **Intelligent Routing:**
    - **Auto-Approval:** Quotes with low-risk discounts (`Approval_Required_Flag__c == false`) are instantly approved by the system, setting an `Is_Automated__c` audit flag for the BI team.
    - **Manual Escalation:** High-discount quotes are locked into a `Submitted` Record Type, requiring a Manager's manual review before they can be finalized.
- **Empty Quote Prevention:** A strict validation rule within the trigger blocks submission of quotes that do not contain at least one line item.

### 4. Dynamic UI Governance
- **Record Type Synchronization:** Automatically switches the `RecordTypeId` based on the approval state. This ensures that the Salesforce Page Layout changes dynamically (e.g., locking fields once a quote is "Submitted").

## 🛠️ Technical Stack
- **Language:** Apex (Triggers & Service-Layer Handlers)
- **Architecture:** Logic-less Triggers (Handler Pattern) for scalability and bulkification.
- **Testing:** 100% Code Coverage achieved, including "Negative Testing" for fallback pricebook scenarios.
- **DevOps:** Developed via VS Code & Salesforce CLI; Version controlled via Git/GitHub.

## 📂 Project Structure
- `force-app/main/default/triggers`: Trigger entry points for Opportunity and Quote objects.
- `force-app/main/default/classes`: Business logic handlers and unit test suites.
