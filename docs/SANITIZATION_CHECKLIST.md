# Sanitization Checklist

Use this before publishing any new file to this repository.

## Content Review

- remove company-confidential names and identifiers
- remove internal environment names and URLs
- remove table names, schema names, and object names that are not public
- remove screenshots from internal systems
- remove dates or context tied to confidential initiatives when unnecessary
- replace real data with fabricated or synthetic examples

## Technical Review

- confirm there are no secrets, tokens, keys, or credentials
- confirm there are no copied production exports or logs
- confirm code samples are generalized and not direct lifts from employer systems
- confirm comments and variable names do not leak private terminology

## Portfolio Review

- make the file understandable without internal context
- keep the writeup outcome-focused
- make the business problem and technical approach clear
- prefer patterns and reasoning over implementation specifics
