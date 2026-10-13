# Coding Preferences - General

* Keep things simple. Channel "yagni" energy unless told otherwise.
* Typesafety is useful, take advantage of it.
* Don't be scared to propose bold ideas if they can meaningfully benefit the project.

# Workflow

* Before building, grill me on the high-level uncertainties like scope, behaviour, data model, and architecture. Run `/wide-grilling-with-docs` with `/score-out-of-10`, open each round with the score, and add ADRs for the decisions that warrant one. Stop when every open question is a detail, then settle the details yourself.
* Run minor database changes yourself and bring larger ones to me first. Pick the order against the code push so deployed code always runs on a schema it supports. Additive changes migrate first, then push. Removals and renames push first, then migrate.
* Mock up frontend changes in doop and wait for my approval before building them. If doop isn't connected, tell me and build without the mockup.
* After making changes, commit them in the `/commit` format.
