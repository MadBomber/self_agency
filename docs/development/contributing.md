# Contributing

## Getting Started

1. Fork the repository
2. Clone your fork
3. Install dependencies: `bin/setup`
4. Create a feature branch: `git checkout -b my-feature`
5. Make your changes
6. Run the tests: `rake test`
7. Commit and push
8. Open a pull request

## Guidelines

### Code Style

- Follow existing patterns in the codebase
- All private helpers are prefixed `self_agency_` to avoid name collisions with host classes
- Keep the gem's runtime dependency count minimal

### Testing

- All tests must pass offline (no LLM connection required)
- Add tests for new features or bug fixes
- Test validation, sanitization, and security patterns directly

### Security

- Any changes to `DANGEROUS_PATTERNS` or `Sandbox` must be carefully reviewed
- New patterns should have corresponding test cases
- The two-layer security model (static + runtime) should be maintained

### Documentation

- Update relevant docs pages for user-facing changes
- Run `mkdocs serve` to preview documentation changes locally

## Reporting Issues

Report bugs and feature requests on [GitHub Issues](https://github.com/madbomber/self_agency/issues).

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
