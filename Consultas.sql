CREATE TABLE contribuicoes_desenvolvedores (
    id SERIAL PRIMARY KEY,
    nome_desenvolvedor TEXT NOT NULL,
    versao_release TEXT NOT NULL,
    quantidade_commits INT NOT NULL
);

COPY contribuicoes_desenvolvedores(nome_desenvolvedor, versao_release, quantidade_commits)
FROM 'c:/developer_contributions.csv'
DELIMITER ','
CSV HEADER;

-- Total de desenvolvedores das 100 releases
WITH releases_subconjunto AS (
    SELECT DISTINCT versao_release 
    FROM contribuicoes_desenvolvedores
    ORDER BY versao_release DESC
    LIMIT 100  -- Seleciona as 100 releases mais recentes
)
SELECT COUNT(DISTINCT nome_desenvolvedor) AS total_desenvolvedores_100_releases
FROM contribuicoes_desenvolvedores
WHERE versao_release IN (SELECT versao_release FROM releases_subconjunto);


-- Percentual de participação ao lado das releases participadas
WITH participacao_desenvolvedores AS (
    SELECT nome_desenvolvedor, 
           COUNT(DISTINCT versao_release) AS total_releases_participadas,
           (SELECT COUNT(DISTINCT versao_release) FROM contribuicoes_desenvolvedores) AS total_releases
    FROM contribuicoes_desenvolvedores
    GROUP BY nome_desenvolvedor
)
SELECT nome_desenvolvedor, 
       total_releases_participadas, 
       total_releases, 
       ROUND((total_releases_participadas * 100.0) / total_releases, 2) AS percentual_participacao
FROM participacao_desenvolvedores
ORDER BY percentual_participacao DESC;


-- Percentual de desenvolvedores que permanecem ativos no maior intervalo de tempo
WITH total_devs AS (
    SELECT COUNT(DISTINCT nome_desenvolvedor) AS total_desenvolvedores 
    FROM contribuicoes_desenvolvedores
),
desenvolvedores_longo_prazo AS (
    SELECT nome_desenvolvedor, COUNT(DISTINCT versao_release) AS total_releases
    FROM contribuicoes_desenvolvedores
    GROUP BY nome_desenvolvedor
    HAVING COUNT(DISTINCT versao_release) >= (SELECT MAX(total_releases) * 0.5 FROM (
        SELECT nome_desenvolvedor, COUNT(DISTINCT versao_release) AS total_releases
        FROM contribuicoes_desenvolvedores
        GROUP BY nome_desenvolvedor
    ) subconsulta)  -- Aqui você pode ajustar o critério (ex: 50% do máximo de releases possíveis)
)
SELECT COUNT(*) * 100.0 / (SELECT total_desenvolvedores FROM total_devs) AS percentual_devs_longo_prazo
FROM desenvolvedores_longo_prazo;

-- Desenvolvedores que pararam de contribuir (Evasão de desenvolvedores)
SELECT nome_desenvolvedor, MAX(versao_release) AS ultimo_release
FROM contribuicoes_desenvolvedores
GROUP BY nome_desenvolvedor
ORDER BY ultimo_release ASC;

-- Rotatividade de desenvolvedores por release
SELECT versao_release, 
       COUNT(DISTINCT nome_desenvolvedor) AS total_devs
FROM contribuicoes_desenvolvedores
GROUP BY versao_release
ORDER BY versao_release DESC;

-- Desenvolvedores presentes no maior intervalo de releases
SELECT nome_desenvolvedor, 
       MIN(versao_release) AS primeiro_release,
       MAX(versao_release) AS ultimo_release,
       COUNT(DISTINCT versao_release) AS total_releases
FROM contribuicoes_desenvolvedores
GROUP BY nome_desenvolvedor
ORDER BY total_releases DESC;

-- Desenvolvedores mais ativos (por número de commits) e releases envolvidas
SELECT 
    nome_desenvolvedor, 
    SUM(quantidade_commits) AS total_commits, 
    COUNT(DISTINCT versao_release) AS total_releases
FROM contribuicoes_desenvolvedores
GROUP BY nome_desenvolvedor
ORDER BY total_commits DESC;





