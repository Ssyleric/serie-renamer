#!/bin/bash

# Répertoire contenant les séries
base_dir="/volume2/serie"

# Clé API TMDb
api_key="xxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Variables pour le rapport final
total_folders=0
renamed_folders=0
merged_folders=0
manual_check=0
manual_list=()

# Fonction pour obtenir l'année de diffusion et le nom correct d'une série sur TMDb
get_tmdb_info() {
    local series_name="$1"
    local series_id
    local tmdb_title
    local airdate_year

    echo "🔎 Recherche de la série '$series_name' sur TMDb..." >&2

    # Rechercher la série
    result=$(curl -s --get "https://api.themoviedb.org/3/search/tv" --data-urlencode "api_key=$api_key" --data-urlencode "query=$series_name")
    series_id=$(echo "$result" | jq -r '.results[0].id')
    tmdb_title=$(echo "$result" | jq -r '.results[0].name')

    if [[ "$series_id" =~ ^[0-9]+$ ]]; then
        echo "✅ Série trouvée : $tmdb_title (ID: $series_id)" >&2
        airdate_year=$(curl -s "https://api.themoviedb.org/3/tv/$series_id?api_key=$api_key" | jq -r '.first_air_date' | cut -d'-' -f1)

        if [[ ! "$airdate_year" =~ ^[0-9]{4}$ ]]; then
            airdate_year="Inconnu"
        fi

        echo "$tmdb_title|$airdate_year"
        return
    fi

    echo "❌ Série non trouvée sur TMDb." >&2
    echo "Inconnu|Inconnu"
}

# Fonction pour normaliser les noms
normalize_series_name() {
    echo "$1" | sed -E 's/Marvel.s //I' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g'
}

# Dictionnaire pour stocker les séries et éviter les doublons
declare -A series_map

# Lire tous les dossiers et les traiter
find "$base_dir" -mindepth 1 -maxdepth 1 -type d | while IFS= read -r folder_path; do
    folder=$(basename "$folder_path")
    ((total_folders++))

    # Exclure certains répertoires inutiles
    if [[ "$folder" =~ (dump|images|private|snippets|template) ]]; then
        echo "🚫 Ignorer : $folder_path (répertoire exclu)"
        continue
    fi

    echo "📂 Traitement du répertoire : $folder_path"

    # Extraction du nom et de l'année
    if [[ "$folder" =~ \(Recherche ]]; then
        series_name=$(echo "$folder" | sed -E 's/ \(Recherche.*//')
        current_year="Inconnu"
    else
        series_name=$(echo "$folder" | sed -E 's/ \([0-9]{4}\)//')
    fi

    if [[ "$folder" =~ \(([0-9]{4})\) ]]; then
        current_year="${BASH_REMATCH[1]}"
    else
        current_year="Inconnu"
    fi
    echo "📌 Année actuelle du répertoire : $current_year"

    # Récupérer le nom officiel et l'année depuis TMDb
    tmdb_data=$(get_tmdb_info "$series_name")
    tmdb_name=$(echo "$tmdb_data" | cut -d'|' -f1)
    tmdb_year=$(echo "$tmdb_data" | cut -d'|' -f2)

    if [[ "$tmdb_name" == "Inconnu" ]]; then
        echo "⚠️ Impossible de trouver '$series_name' sur TMDb. Vérification manuelle requise."
        manual_list+=("$folder")
        ((manual_check++))
        continue
    fi

    # Construire le nom de dossier correct
    new_folder_name="${tmdb_name} (${tmdb_year})"
    new_folder_path="$base_dir/$new_folder_name"

    # Renommage si nécessaire
    if [[ "$new_folder_name" != "$folder" ]]; then
        echo "🔄 Renommage : '$folder' -> '$new_folder_name'"
        mv "$folder_path" "$new_folder_path"
        ((renamed_folders++))
    fi

    # Vérification des doublons
    normalized_name=$(normalize_series_name "$tmdb_name")
    if [[ -n "${series_map[$normalized_name]}" ]]; then
        target_folder="${series_map[$normalized_name]}"
        echo "🔄 Fusion de '$new_folder_name' -> '$target_folder'"
        mv "$new_folder_path"/* "$target_folder" 2>/dev/null
        rmdir "$new_folder_path" 2>/dev/null && echo "🗑️ Dossier supprimé : $new_folder_path"
        ((merged_folders++))
    else
        series_map[$normalized_name]="$new_folder_path"
    fi
done

# Affichage du rapport final
echo ""
echo "📊 RAPPORT FINAL :"
echo "------------------------"
echo "📂 Total des dossiers traités  : $total_folders"
echo "✍️  Dossiers renommés          : $renamed_folders"
echo "🔄 Dossiers fusionnés         : $merged_folders"
echo "⚠️  Dossiers à vérifier manuellement : $manual_check"

if [[ ${#manual_list[@]} -gt 0 ]]; then
    echo ""
    echo "🚨 LISTE DES DOSSIERS À VÉRIFIER :"
    for folder in "${manual_list[@]}"; do
        echo "   - $folder"
    done
fi

echo "✅ Renommage terminé !"
