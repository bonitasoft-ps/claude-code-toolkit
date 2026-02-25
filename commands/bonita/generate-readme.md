# Generate Controller README.md

Generate a compliant README.md for a REST API controller package.

## Arguments
- `$ARGUMENTS`: controller name or path

## Instructions

1. Find the controller package
2. Read all Java files to extract: HTTP method, endpoint, parameters, request/response structure
3. Read the reference README (executeRestService/README.md) for format
4. Generate README.md with mandatory sections: Overview, Endpoint, Parameters, Request Body, Response, Examples, Error Handling, Files
5. Write to the controller directory
