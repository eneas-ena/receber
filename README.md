# RECEBER

Acolhimento de visitantes e acompanhamento de decisões da Igreja Vidas, com painel de acesso da equipe.

**Abrir o app:** https://eneas-ena.github.io/receber/

## Como funciona

- App feito em página web; pode ser instalado na tela inicial do iPad, iPhone ou Mac.
- Os dados ficam salvos no Supabase, por isso aparecem iguais em todos os aparelhos.

## Observações

- `setup.sql` cria as tabelas e as regras de segurança do banco. Rode de novo no Supabase sempre que recriar um dos dois usuários.
- O acesso é feito por duas senhas, guardadas no Supabase (Authentication → Users): `receber-total@igrejavidas.app` abre o painel completo; `receber-ficha@igrejavidas.app` só envia fichas de decisão. A ficha de visitante não pede senha.

## Como publicar uma nova versão

1. Nesta página do repositório, clique em **Add file → Upload files**.
2. Arraste os arquivos novos, com os mesmos nomes dos antigos.
3. Clique em **Commit changes**.

Em um ou dois minutos a nova versão está no ar no mesmo endereço.

---
Desenvolvido por Bispo Enéas Araújo.
