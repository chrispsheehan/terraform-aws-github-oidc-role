example_dirs:
  @printf '[\n'; \
  first=1; \
  find examples -mindepth 2 -maxdepth 2 -type f -name main.tf | sort | sed 's#/main.tf$##' | \
  while IFS= read -r dir; do \
    if [ $first -eq 0 ]; then \
      printf ',\n'; \
    fi; \
    printf '  "%s"' "$dir"; \
    first=0; \
  done; \
  printf '\n]\n'

validate_dirs:
  @find examples -mindepth 2 -maxdepth 2 -type f -name main.tf | sort | \
    sed 's#/main.tf$##' | jq -R . | jq -sc '["."] + .'
