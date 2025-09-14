#!/bin/bash

# Liste des noms à ignorer
IGNORED_FUNCS=("mount" "handle_event" "handle_info" "render" "update" "terminate" "handle_params" "handle_call" "handle_cast")

# Fichiers logs de sortie
UNUSED_PUBLIC="unused_def.log"
> "$UNUSED_PUBLIC"


echo "🔍 Analyse des fonctions publiques (def)..."

grep -rn '^[[:space:]]*def ' lib/ | grep -vE 'defmodule|defmacro|defdelegate|defimpl' | while read -r line; do
  if [[ $line =~ def[[:space:]]+([a-zA-Z0-9_]+) ]]; then
    FUNC_NAME="${BASH_REMATCH[1]}"

    if printf '%s\n' "${IGNORED_FUNCS[@]}" | grep -qx "$FUNC_NAME"; then
      continue
    fi

    MATCHES=$(grep -rn "$FUNC_NAME" lib/)
    USED=false
    while IFS= read -r match; do
      if [[ ! $match =~ def[[:space:]]+$FUNC_NAME ]]; then
        USED=true
        break
      fi
    done <<< "$MATCHES"

    if [[ $USED = false ]]; then
      echo "❌ def inutilisée : $FUNC_NAME"
      echo "$line" >> "$UNUSED_PUBLIC"
    fi
  fi
done

echo ""
echo "✅ Terminé !"
echo "🔸 Fonctions publiques inutilisées → $UNUSED_PUBLIC"