# Zettelkasten Index

## Current Structure

This zettelkasten system organizes knowledge using Luhmann's slip-box method with hierarchical numbering for permanent notes and timestamp-based unique IDs.

## Core Files

- [rules.md](rules.md) - Zettelkasten rules, guidelines, and naming conventions
- [reference.md](reference.md) - Template for creating new notes with proper frontmatter
- [update_zettelkasten_index.sh](update_zettelkasten_index.sh) - Script to update the index

## Method Documentation

### method/
Contains notes about the zettelkasten methodology and implementation

- [lumnannotes.md](2-zettelkasten-method/lumnannotes.md) - Notes on Luhmann's slip-box method, PARA methodology, and implementation details

## Key Principles

- One idea per note - Each note contains a single atomic concept
- Hierarchical numbering - Permanent notes use 10-, 11-, 111- style numbering
- Timestamp IDs - Each note has a unique timestamp-based identifier
- Bidirectional linking - Notes reference each other to create a web of knowledge
- Separation of concerns - Ephemeral notes (0-zettelkasten/) vs permanent reference material (1-resources/)

## Usage

1. Create fleeting notes in `0-zettelkasten/` for immediate thoughts
2. Process and refine them into permanent notes in appropriate `1-resources/` subdirectories
3. Use the hierarchical numbering system (10-, 11-, 111-) for organization
4. Link related notes using the `links:` field in frontmatter
5. Use tags sparingly for cross-cutting concerns
