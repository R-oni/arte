# Roni Ricardo — Informação é Ouro

## Estrutura do Projeto

```
roniricardo/
├── index.html              # Landing page (roniricardo.com)
├── dashboard.html          # Dashboard dos clientes (?c=N)
├── styles.css              # Estilos (landing + dashboard)
├── script.js               # Lógica do dashboard
├── assinatura.gif          # Logo animada
├── assinatura_final.png    # Logo estática (pós-animação)
├── logo-cinza-rosa.png     # Logo do cliente #1
├── CNAME                   # Domínio roniricardo.com
└── clientes/
    ├── 1/                  # Salão Beauty Pro
    │   ├── meta.json       # Config: nome, tema, gráficos
    │   ├── dados.json      # KPIs e dados (gerado)
    │   ├── processar.py    # CSV → JSON
    │   └── *.csv           # Dados brutos
    └── 2/                  # PetCare Plus
        ├── meta.json
        ├── dados.json
        ├── processar.py
        └── *.csv
```

## Como Adicionar um Cliente Novo

1. Criar pasta `clientes/N/`
2. Colocar os CSVs do cliente na pasta
3. Copiar `processar.py` de outro cliente e ajustar colunas se necessário
4. Criar `meta.json` com nome, tema e gráficos
5. Rodar `python clientes/N/processar.py`
6. Acessar `dashboard.html?c=N`

## Como Atualizar Dados Mensais

1. Receber novo CSV do cliente via WhatsApp
2. Salvar em `clientes/N/`
3. Rodar `python clientes/N/processar.py`
4. Enviar link do dashboard ao cliente

---

**Desenvolvido para SaaS de Microempresas** 💼
