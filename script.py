import requests
import csv
from concurrent.futures import ThreadPoolExecutor, as_completed

repo_owner = "angular"
repo_name = "angular"
api_url = f"https://api.github.com/repos/{repo_owner}/{repo_name}"
GITHUB_TOKEN = ""  # Substitua pelo seu token gerado
HEADERS = {"Authorization": f"token {GITHUB_TOKEN}"}

def get_last_releases():
    releases = []
    page = 1
    per_page = 100  # máximo permitido pelo GitHub
    
    while len(releases) < 100:  # Limitamos para 100 releases
        releases_url = f"{api_url}/releases?per_page={per_page}&page={page}"
        response = requests.get(releases_url, headers=HEADERS)
        
        if response.status_code == 200:
            data = response.json()
            if not data:
                break  # sem mais releases
            releases.extend(data)
            page += 1
        else:
            print("Erro ao acessar releases:", response.status_code, response.text)
            break
    
    return releases[:100]  # Garante que retorna no máximo 100 releases

def get_commits_for_release(tag_name):
    commits = []
    page = 1
    while True:
        commits_url = f"{api_url}/commits?sha={tag_name}&per_page=100&page={page}"
        response = requests.get(commits_url, headers=HEADERS)
        if response.status_code == 200:
            data = response.json()
            if not data:
                break
            commits.extend(data)
            page += 1
        else:
            print(f"Erro ao acessar commits para {tag_name}: {response.status_code}, {response.text}")
            break
    return commits


def analyze_developer_contributions():
    releases = get_last_releases()
    developer_contributions = {}

    # Usando ThreadPoolExecutor para buscar commits em paralelo
    with ThreadPoolExecutor(max_workers=10) as executor:
        future_to_tag = {executor.submit(get_commits_for_release, release['tag_name']): release['tag_name'] for release in releases}
        
        for future in as_completed(future_to_tag):
            tag_name = future_to_tag[future]
            try:
                commits = future.result()
            except Exception as exc:
                print(f"Erro na release {tag_name}: {exc}")
                continue

            for commit in commits:
                author = commit.get("commit", {}).get("author", {}).get("name")
                if author:
                    if author not in developer_contributions:
                        developer_contributions[author] = {}
                    if tag_name not in developer_contributions[author]:
                        developer_contributions[author][tag_name] = 0
                    developer_contributions[author][tag_name] += 1
    return developer_contributions

def save_to_csv(developer_contributions):
    with open('developer_contributions.csv', mode='w', newline='', encoding='utf-8') as file:
        writer = csv.writer(file)
        writer.writerow(["Developer", "Release", "Commits"])
        for developer, releases in developer_contributions.items():
            for release, commits in releases.items():
                writer.writerow([developer, release, commits])

def main():
    print("Analisando a rotatividade de desenvolvedores no repositório Angular...")
    developer_contributions = analyze_developer_contributions()
    save_to_csv(developer_contributions)
    print("\nCSV com as contribuições dos desenvolvedores foi gerado com sucesso!")

if __name__ == "__main__":
    main()
