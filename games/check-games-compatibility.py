#!/usr/bin/env python3

import argparse
import csv
import requests

# Returns list of dicts [{id: 1, name: '', source: ''}]
def parse_csv(csv_path):
    with open(csv_path, newline='', encoding='utf-8') as csv_file:
        games = []
        reader = csv.DictReader(csv_file)
        for row in reader:
            games.append({
                'id': row['Game Id'],
                'name': row['Name'],
                'source': row['Sources']
            })

        return games

# Returns a dict of name keys and ID values
def get_steam_apps():
    # https://partner.steamgames.com/doc/webapi/ISteamApps
    # GET
    # {"applist":{"apps":[{"appid":216938,"name":"Pieterw test app76 ( 216938 )"}]}}
    url = 'https://api.steampowered.com/ISteamApps/GetAppList/v2/'

    response = requests.get(url)

    if response.status_code != 200:
        print(f'Steam API request for apps list failed with status code {response.status_code}')
        return None

    apps = response.json()['applist']['apps']

    apps_map = {}
    for app in apps:
        apps_map[app['name'].casefold()] = app['appid']

    return apps_map

def is_steam_game(game):
    return game['source'] == 'Steam'

def is_gog_game(game):
    return game['source'] == 'GOG'

def is_epic_game(game):
    return game['source'] == 'Epic'

def is_itch_game(game):
    return game['source'] == 'itch.io'

def is_humble_game(game):
    return game['source'] == 'Humble'

def is_ubisoft_game(game):
    return game['source'] == 'Ubisoft Connect'

def is_ea_game(game):
    return game['source'] == 'EA app'

def is_microsoft_game(game):
    return game['source'] == 'Xbox'

# For a Steam game, just return its ID.
# For other games, use the game name to try to look up the Steam ID (if it's on Steam)
def get_steam_game_id(game, steam_apps):
    if is_steam_game(game):
        return game['id']

    name = game['name'].casefold()

    if name in steam_apps:
        return steam_apps[name]
    else:
        print(f'Could not find Steam ID for {game['name']}')
        return None

def get_protondb_summary(steam_game_id):
    url = f'https://www.protondb.com/api/v1/reports/summaries/{steam_game_id}.json'
    response = requests.get(url)

    if response.status_code != 200:
        print(f'ProtonDB request failed with status code {response.status_code} for game ID {steam_game_id}')
        return None

    # {
    #     "bestReportedTier": "platinum",
    #     "confidence": "inadequate",
    #     "provisionalTier": "platinum",
    #     "score": 0.34,
    #     "tier": "pending",
    #     "total": 7,
    #     "trendingTier": "pending"
    # }
    return response.json()

def is_gog_game_on_linux(game_id):
    url = f'https://www.gogdb.org/data/products/{game_id}/product.json'
    response = requests.get(url)

    if response.status_code != 200:
        print(f'GOG DB request failed with status code {response.status_code} for game ID {game_id}')
        return None

    return 'linux' in response.json()['comp_systems']

def is_steam_game_on_linux(game_id):
    url = f'https://www.protondb.com/proxy/steam/api/appdetails/?appids={game_id}'
    response = requests.get(url)

    if response.status_code != 200:
        print(f'Steam API request failed with status code {response.status_code} for game ID {game_id}')
        return None

    result = response.json()[game_id]
    if result['success']:
        return result['data']['platforms']['linux']
    else:
        print(f'Failed to fetch Steam data for game ID {game_id}')
        return False

def is_itch_game_on_linux(game_id, itch_api_key):
    if itch_api_key is None:
        return None

    url = f'https://api.itch.io/games/{game_id}'

    response = requests.get(url, headers={'authorization': f'Bearer {itch_api_key}'})

    if response.status_code != 200:
        print(f'itch.io API request failed with status code {response.status_code} for game ID {game_id}')
        return None

    return 'p_linux' in response.json()['game']['traits']

def is_humble_game_on_linux(game_id):
    # Unfortunately Humble Bundle's Cloudflare protection blocks requests made from this script, even if the headers are identical to what my web browser sends and both are using HTTP/2 and TLS 1.3 with the same cipher suite.

    # Playnite's Humble game IDs are of the form <machine name>_<human name>
    # <https://github.com/JosefNemec/PlayniteExtensions/blob/master/source/Libraries/HumbleLibrary/HumbleLibrary.cs#L114>
    # Unforunately the only API endpoint I know is useful takes product values, and they don't necessarily match either the machine name or the human name.
    # For single-word names the machine name is likely to match the product value, so try it.
    machine_name = game_id.split('_')[0]
    url = f'https://www.humblebundle.com/store/api/lookup?products%5B%5D={machine_name}&request=1'
    # These headers are needed to stop Cloudflare protection from blocking access.
    headers = {
        'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:131.0) Gecko/20100101 Firefox/131.0',
        'accept-language': 'en-US',
        'te': 'trailers',
        'priority': 'u=0, i'
    }

    response = requests.get(url, headers=headers)

    if response.status_code != 200:
        print(f'Humble Bundle API request failed with status code {response.status_code} for game ID {game_id}')
        print('Request headers were', response.request.headers)
        exit(1)
        return None

    result = response.json()['result']

    if len(result) == 0:
        return None

    return 'linux' in result[0]['platforms']

def is_on_linux(game, itch_api_key):
    if is_steam_game(game):
        return is_steam_game_on_linux(game['sourceId'])
    elif is_gog_game(game):
        return is_gog_game_on_linux(game['sourceId'])
    elif is_itch_game(game):
        return is_itch_game_on_linux(game['sourceId'], itch_api_key)
    elif is_humble_game(game):
        return is_humble_game_on_linux(game['sourceId'])
    elif is_ea_game(game) or is_epic_game(game) or is_microsoft_game(game) or is_ubisoft_game(game):
        return False
    else:
        return None

def get_proton_compatibility(steam_ids):
    results = {}
    for id in steam_ids:
        protondb_summary = get_protondb_summary(id)

        if protondb_summary:
            if protondb_summary['tier'] == 'pending':
                results[id] = protondb_summary['provisionalTier'] + ' (provisional)'
            else:
                results[id] = protondb_summary['tier']
        else:
            results[id] = 'Unknown'

    return results

def update_game_data(game, proton_data, itch_api_key):
    steam_id = game['steamId']
    if steam_id:
        game['protonCompatibility'] = proton_data[steam_id]

    linux = is_on_linux(game, itch_api_key)
    if linux is not None:
        game['hasLinuxBuild'] = 'Yes' if linux else 'No'

def process_games(games, itch_api_key):
    steam_apps = get_steam_apps()

    steam_ids = set()
    games_data = []
    for game in games:
        steam_id = get_steam_game_id(game, steam_apps)

        if steam_id is not None:
            steam_ids.add(steam_id)

        games_data.append({
            'name': game['name'],
            'source': game['source'],
            'sourceId': game['id'],
            'steamId': steam_id,
            'protonCompatibility': 'Unknown',
            'hasLinuxBuild': 'Unknown'
        })

    proton_data = get_proton_compatibility(steam_ids)

    for game in games_data:
        update_game_data(game, proton_data, itch_api_key)

    return games_data

def collect_stats(games_data):
    games_count = len(games_data)
    proton_platinum_count = 0
    proton_gold_count = 0
    proton_silver_count = 0
    proton_bronze_count = 0
    proton_borked_count = 0
    proton_unknown_count = 0
    linux_supported_count = 0

    for game in games_data:
        proton = game['protonCompatibility']
        if proton.startswith('platinum'):
            proton_platinum_count += 1
        elif proton.startswith('gold'):
            proton_gold_count += 1
        elif proton.startswith('silver'):
            proton_silver_count += 1
        elif proton.startswith('bronze'):
            proton_bronze_count += 1
        elif proton.startswith('borked'):
            proton_borked_count += 1
        elif proton == 'Unknown':
            proton_unknown_count += 1

        if game['hasLinuxBuild'] == 'Yes':
            linux_supported_count += 1

    return {
        'games_count': games_count,
        'proton_platinum_count': proton_platinum_count,
        'proton_gold_count': proton_gold_count,
        'proton_silver_count': proton_silver_count,
        'proton_bronze_count': proton_bronze_count,
        'proton_borked_count': proton_borked_count,
        'proton_unknown_count': proton_unknown_count,
        'linux_supported_count': linux_supported_count
    }

def write_csv(csv_path, games_data):
    with open(csv_path, 'w', newline='', encoding='utf-8') as csv_file:
        field_names = ['name', 'source', 'sourceId', 'steamId', 'protonCompatibility', 'hasLinuxBuild']
        writer = csv.DictWriter(csv_file, fieldnames=field_names)

        writer.writeheader()
        for game in games_data:
            writer.writerow(game)

def main():
    parser = argparse.ArgumentParser(description='Supply the path to a CSV file containing your game library.')
    parser.add_argument('csv_input_path')
    parser.add_argument('csv_output_path')
    parser.add_argument('-i', '--itch-api-key')
    args = parser.parse_args()

    games = parse_csv(args.csv_input_path)

    games_data = process_games(games, args.itch_api_key)

    stats = collect_stats(games_data)

    print('Game stats:', stats)

    write_csv(args.csv_output_path, games_data)

if __name__ == "__main__":
    main()
