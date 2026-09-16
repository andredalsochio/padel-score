# Padel Score

Aplicativo Flutter para registrar partidas de padel, placares e formações de jogadores por set.

## Visão geral

O app acompanha a partida desde a definição dos jogadores até o registro dos sets. A composição de cada set fica explícita, permitindo consultar o placar e preservar o contexto de quem jogou em cada momento.

## Destaques

- Registro de partidas e placares.
- Definição da composição dos jogadores por set.
- Resumo da partida e dos sets.
- Estado da aplicação organizado com Provider.
- Navegação declarativa com GoRouter.
- Persistência transacional no Supabase por meio da RPC `save_game_with_sets`.
- Testes automatizados para apoiar a evolução da lógica.

## Stack

- Flutter
- Dart 3.9+
- Supabase
- Provider
- GoRouter
- Shared Preferences

## Como executar

Pré-requisitos: Flutter SDK instalado e um projeto Supabase configurado para a aplicação.

```bash
flutter pub get
flutter run
```

Para validar o projeto:

```bash
flutter analyze
flutter test
```

Configure as credenciais do Supabase conforme os arquivos de configuração do projeto. Não versionar chaves privadas.

## Persistência

A aplicação usa a tabela `public.score_set_players` para armazenar a escalação por jogo e set. A RPC `public.save_game_with_sets` concentra o salvamento do jogo e de seus sets em uma operação transacional.

## Estrutura

```text
lib/              # Código da aplicação
assets/config/    # Configurações e recursos
test/             # Testes
android/ ios/ web/ # Plataformas suportadas
```

## Contexto

Projeto público de portfólio que explora desenvolvimento mobile, modelagem de dados e persistência transacional em um produto de placar para partidas de padel.
