## Setup Instructions (delete this section)

1. Create new repo in the **ipsos-cicd-tools** Github org using this repo as the template in the drop down option. 
    - Use the naming schema **"tf-(CLOUD-PROVIDER)-(MODULE-NAME)"** 
        - CLOUD-PROVIDER can be `gcp`, `az`, or `aws`
        - Be sure to keep it all in lowercase

2. Branch protection is enabled for `main` so any changes will need to be made via Pull Requests 

3. Rename the folder `/modules/module_name` to the name of your module.  example: `/modules/cloud-run-service`

4. Delete this section of the README and use the rest as a template for setting one up
<br>
<br>


# Terraform $REPO_NAME Module

Brief description of module

## Compatibility
Any compatability concerns go here

## Useage 
More specific useage examples can be found in the ***modules*** folder under the corresponding module name

```
module "module_name" {
source  = "git::https://github.com/ipsos-cicd-tools/<repo name>//modules/<module name>?ref=<version number>"

## Required Variables ##
project_id  = 
region  = 
service_name  = 
}
```
<br>
<br>
<br>

# Committing to a GitHub Repository Using Semantic Versioning

![GitHub](https://img.shields.io/badge/GitHub-Semantic%20Versioning-brightgreen)

Semantic Versioning is a versioning scheme that helps maintainers and users of a software project understand the nature of changes between versions. When committing to a GitHub repository that follows Semantic Versioning, it's essential to adhere to certain guidelines to maintain version consistency and clarity.

## Semantic Versioning Basics

Semantic Versioning follows a `MAJOR.MINOR.PATCH` format, where:

- ![Major](https://img.shields.io/badge/MAJOR-red)![1.0.0](https://img.shields.io/badge/1.0.0-grey) indicates incompatible changes (backwards-incompatible).
- ![Minor](https://img.shields.io/badge/MINOR-yellow)![0.1.0](https://img.shields.io/badge/0.1.0-grey) denotes new features that are backward-compatible.
- ![Patch](https://img.shields.io/badge/PATCH-brightgreen)![0.0.1](https://img.shields.io/badge/0.0.1-grey) represents bug fixes and backward-compatible improvements.

## Commit Message Conventions

To maintain SemVer in your GitHub repository, commit messages should follow a specific convention. Each commit message should include:

1. **Type**: A one-word type that describes the nature of the change. Common types include:
   - ![Breaking_Change](https://img.shields.io/badge/BREAKING__CHANGE:-red) A major change that would break existing deployments (increment ![MAJOR](https://img.shields.io/badge/MAJOR-red)).
   - ![Feature](https://img.shields.io/badge/feat:-yellow) A new module introduced (increment ![MINOR](https://img.shields.io/badge/MINOR-yellow)).
   - ![Bug Fix](https://img.shields.io/badge/fix:-brightgreen) A bug fix (increment ![PATCH](https://img.shields.io/badge/PATCH-brightgreen)).
   - ![Documentation](https://img.shields.io/badge/docs:-lightgrey) Documentation updates (increment ![NONE](https://img.shields.io/badge/none-lightgrey)).

2. **Description**: A brief, concise description of the change.

3. **Jira Task** (Optional): Add the task ID to the related Jira task or epic.

### Example Commit Message
``` 
git commit -m "fix: added description to resource TST-34"