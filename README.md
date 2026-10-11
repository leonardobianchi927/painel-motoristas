# RavieraGroup — Portal de motoristas com Supabase

Portal estático para GitHub Pages com autenticação Supabase, consulta de fichas e edição diária de perfis por **administrador e gerentes**.

## Arquivos
- `index.html`: site.
- `config.js`: configuração pública do Supabase (você precisa preencher).
- `config.example.js`: modelo da configuração.
- `supabase/schema.sql`: tabelas, permissões RLS e os seis perfis iniciais.

## 1. Criar o projeto Supabase
1. Acesse https://supabase.com/ e crie um projeto.
2. Guarde a senha do banco em local seguro; não a coloque no GitHub.
3. No painel do projeto, abra **SQL Editor** → **New query**.
4. Abra `supabase/schema.sql` deste pacote, copie todo o conteúdo, cole no SQL Editor e clique **Run**.
5. Vá a **Project Settings → API** (ou **Connect**, conforme a versão da interface). Copie a **Project URL** e a chave pública **anon / publishable**.
6. Edite `config.js` e substitua:
   - `https://SEU-PROJETO.supabase.co` pela Project URL.
   - `COLE_SUA_CHAVE_ANON_PUBLICA_AQUI` pela chave pública anon/publishable.

   Nunca use a chave `service_role` ou uma chave secreta no site. A chave pública é esperada no navegador; as regras RLS do SQL protegem as tabelas.

## 2. Criar a conta de administrador
1. No Supabase, abra **Authentication → Users → Add user** (ou **Create new user**).
2. Cadastre seu e-mail e uma senha forte. Se houver a opção de confirmar e-mail, confirme a conta conforme solicitado.
3. Depois de criar o usuário, abra **SQL Editor** e execute o comando abaixo, trocando pelo mesmo e-mail usado no cadastro:

```sql
update public.user_profiles up
set role = 'admin', display_name = 'Administrador Raviera'
from auth.users au
where au.id = up.id and au.email = 'SEU-EMAIL@EXEMPLO.COM';
```

4. Para cada gerente, crie uma conta separada em **Authentication → Users** e execute, trocando e-mail e nome:

```sql
update public.user_profiles up
set role = 'manager', display_name = 'Nome do Gerente'
from auth.users au
where au.id = up.id and au.email = 'EMAIL-DO-GERENTE@EXEMPLO.COM';
```

5. Motoristas que só consultam o portal devem ficar com `role = 'driver'`. O sistema não tem cadastro público de contas; isso é intencional para evitar que qualquer pessoa se promova a gerente.

Se o usuário foi criado antes de executar `schema.sql` e não ganhou um perfil automaticamente, execute o `UPDATE` acima. Se não houver linha em `user_profiles`, rode:

```sql
insert into public.user_profiles (id, display_name, role)
select id, 'Administrador Raviera', 'admin'
from auth.users where email = 'SEU-EMAIL@EXEMPLO.COM'
on conflict (id) do update set role = 'admin';
```

## 3. Publicar no GitHub Pages
1. Extraia o ZIP no computador.
2. Abra o repositório do portal no GitHub.
3. Envie para a **raiz** do repositório estes itens: `index.html`, `config.js`, `config.example.js`, a pasta `supabase/` e este README. Não envie apenas o ZIP.
4. Confirme que `index.html` aparece na primeira página do repositório, não dentro de outra pasta.
5. Vá a **Settings → Pages**. Em **Build and deployment**, selecione **Deploy from a branch**, branch `main` e pasta `/(root)`, e salve.
6. Aguarde a publicação e abra a URL mostrada em Settings → Pages. Pode levar alguns minutos.

## 4. Como atualizar os perfis todos os dias
1. Entre no site com o e-mail e senha da conta.
2. Abra **Motoristas cadastrados** e escolha o motorista.
3. Se tiver perfil `admin` ou `manager`, o formulário **Atualizar ficha** aparecerá.
4. Altere dinheiro na conta, caminhão, reboque, CNH, multas e, se necessário, nome/QRA; clique **Salvar alterações**.
5. Os dados ficam no Supabase, portanto não é necessário editar nem republicar o HTML para as atualizações diárias. Use **Atualizar** para recarregar os dados.

## 5. Segurança e observações
- Administradores e gerentes podem editar perfis; motoristas autenticados só podem consultar.
- A permissão é verificada no banco com Row Level Security (RLS), não apenas pelo visual do site.
- Não compartilhe contas entre gerentes; crie um login individual para cada pessoa e remova acessos de quem sair da equipe.
- Não publique senhas, chaves secretas ou `service_role` no GitHub. `config.js` contém apenas a chave pública do Supabase.
- Como o portal é hospedado no GitHub Pages, qualquer pessoa que saiba a URL pode abrir a tela de login. O acesso aos dados depende de uma sessão autenticada.
- O portal inicializa seis motoristas com dados “A definir”. Os nomes/QRA podem ser ajustados por administrador/gerente depois do login.
- O projeto não possui recuperação de senha customizada nem criação de contas dentro do site; gerencie as contas pelo painel Supabase.
