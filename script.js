// Sistema de clientes - carregado do arquivo JSON
let clients = {};

let charts = {};
let currentClient = null;

// Carregar dados do cliente específico (baseado em URL ?c=N)
async function carregarDadosClientes() {
    try {
        const params = new URLSearchParams(window.location.search);
        const clientId = params.get('c') || '1';
        
        // Carregar meta.json (info do cliente)
        const metaResponse = await fetch(`clientes/${clientId}/meta.json`);
        const meta = await metaResponse.json();
        
        // Carregar dados.json (KPIs, vendas, etc)
        const dataResponse = await fetch(`clientes/${clientId}/dados.json`);
        const dados = await dataResponse.json();
        
        // Montar estrutura compatível
        clients[clientId] = {
            ...meta,
            data: dados
        };
        
        console.log(`Cliente #${clientId} carregado:`, clients[clientId]);
        return true;
    } catch (error) {
        console.error('Erro ao carregar dados do cliente:', error);
        console.warn('Usando estrutura vazia - verifique se clientes/N/dados.json existe');
        return false;
    }
}

// Congelar GIF no último frame após animação
function freezeSignatureGif() {
    const gifElement = document.querySelector('.signature-img');
    if (!gifElement) return;
    
    // Aguardar 500ms (duração do GIF) e trocar para PNG estático
    setTimeout(() => {
        gifElement.src = 'assinatura_final.png';
    }, 3050);
}

// Inicializar
document.addEventListener('DOMContentLoaded', async () => {
    freezeSignatureGif();
    await carregarDadosClientes();
    loadClient();
    setupEventListeners();
    updateDate();
});

// Carregar cliente da URL
function loadClient() {
    const params = new URLSearchParams(window.location.search);
    const clientId = params.get('c') || '1';
    
    if (!clients[clientId]) {
        console.error(`[ERRO] Cliente #${clientId} não foi carregado. Verifique clientes/${clientId}/dados.json`);
        return;
    }
    
    currentClient = clients[clientId];

    const logoEl = document.getElementById('clientLogo');
    if (logoEl) {
        if (currentClient.logo) {
            logoEl.src = currentClient.logo;
            logoEl.style.display = 'block';
        } else {
            logoEl.style.display = 'none';
        }
    }

    // Usar o último mês disponível (mais recente)
    const mesesDisponiveis = Object.keys(currentClient.data);
    const primeiroMes = mesesDisponiveis.length > 0 ? mesesDisponiveis[mesesDisponiveis.length - 2] : 'janeiro';
    
    // Atualizar o seletor com os meses disponíveis
    const selectMes = document.getElementById('month-select');
    selectMes.innerHTML = '';
    mesesDisponiveis.forEach(mes => {
        const option = document.createElement('option');
        option.value = mes;
        option.textContent = mes.charAt(0).toUpperCase() + mes.slice(1);
        selectMes.appendChild(option);
    });
    selectMes.value = primeiroMes;
    
    // Renderizar containers de gráficos
    renderChartContainers();
    
    updateDashboard(primeiroMes);
}

// Setup listeners
function setupEventListeners() {
    document.getElementById('month-select').addEventListener('change', (e) => {
        updateDashboard(e.target.value);
    });
}

// Atualizar dashboard
function updateDashboard(month) {
    const data = currentClient.data[month];
    
    document.getElementById('kpi-faturamento').textContent = formatCurrency(data.faturamento);
    document.getElementById('kpi-vendas').textContent = data.vendas.toLocaleString('pt-BR');
    document.getElementById('kpi-ticket').textContent = formatCurrency(data.faturamento / data.vendas);
    document.getElementById('kpi-clientes').textContent = data.clientes.toLocaleString('pt-BR');
    
    updateChangeIndicator('change-faturamento', data.changeFaturamento);
    updateChangeIndicator('change-vendas', data.changeVendas);
    updateChangeIndicator('change-ticket', data.changeTicket);
    updateChangeIndicator('change-clientes', data.changeClientes);
    
    renderCustomCharts();
}

// Atualizar indicadores
function updateChangeIndicator(id, value) {
    const el = document.getElementById(id);
    const prefix = value >= 0 ? '+' : '';
    el.textContent = `${prefix}${value.toFixed(1)}%`;
    el.style.color = value >= 0 ? 'var(--success)' : '#ef4444';
}

// Formatar moeda
function formatCurrency(value) {
    return new Intl.NumberFormat('pt-BR', {
        style: 'currency',
        currency: 'BRL',
        minimumFractionDigits: 0
    }).format(value);
}

// ===== SISTEMA DE GRÁFICOS DINÂMICOS =====

/**
 * Renderiza containers de gráficos baseado na configuração do cliente
 */
function renderChartContainers() {
    const container = document.getElementById('charts-container');
    if (!container) return;

    container.innerHTML = ''; // Limpar gráficos anteriores

    if (!currentClient.charts || currentClient.charts.length === 0) {
        container.innerHTML = '<p style="text-align: center; color: #94a3b8;">Sem gráficos configurados</p>';
        return;
    }

    currentClient.charts.forEach((chartConfig, index) => {
        const div = document.createElement('div');
        div.className = 'chart-mini fade-in';
        div.style.animationDelay = `${0.5 + index * 0.1}s`;
        
        const canvasId = chartConfig.id + '-chart';
        const corBorda = currentClient.color_theme || '#cbd5e1';
        div.innerHTML = `
            <h3>${chartConfig.titulo || 'Gráfico'}</h3>
            <div class="chart-canvas-wrapper" id="${chartConfig.id}-wrapper">
                <canvas id="${canvasId}"></canvas>
            </div>
            <p class="chart-insight" style="margin-top: 1rem; font-size: 0.9rem; color: #cbd5e1; font-style: italic; border-left: 3px solid ${corBorda}; padding-left: 0.75rem; line-height: 1.5;">Insight...</p>
        `;
        
        container.appendChild(div);
    });
}

/**
 * Renderiza gráficos baseado na configuração do cliente (meta.json)
 */
function renderCustomCharts() {
    if (!currentClient.charts || currentClient.charts.length === 0) {
        return;
    }

    // Destruir gráficos antigos
    Object.values(charts).forEach(chart => chart && chart.destroy());
    charts = {};

    // Renderizar cada gráfico configurado
    currentClient.charts.forEach(chartConfig => {
        const container = document.getElementById(chartConfig.id + '-chart');
        if (!container) {
            console.warn(`Container não encontrado para ${chartConfig.id}-chart`);
            return;
        }

        const chartData = getDataForChart(chartConfig.dataSource);
        if (!chartData) {
            console.warn(`Dados não encontrados para ${chartConfig.dataSource}`);
            return;
        }

        // Altura dinâmica para barras horizontais
        if (chartConfig.tipo === 'bar' && chartConfig.posicao === 'esquerda') {
            const wrapper = document.getElementById(chartConfig.id + '-wrapper');
            if (wrapper) {
                const numItems = chartData.labels.length;
                wrapper.style.height = Math.max(200, numItems * 38 + 60) + 'px';
            }
        }

        const config = createChartConfig(chartConfig, chartData);
        charts[chartConfig.id] = new Chart(container.getContext('2d'), config);
        
        // Preencher insight abaixo do gráfico
        const insightText = generateInsight(chartConfig, chartData, chartConfig.dataSource);
        const insightEl = container.closest('.chart-mini').querySelector('.chart-insight');
        if (insightEl) {
            insightEl.textContent = insightText;
        }
    });
}

/**
 * Retorna dados baseado no dataSource configurado
 */
function getDataForChart(dataSource) {
    const mesAtual = document.getElementById('month-select').value;
    const dataAtual = currentClient.data[mesAtual];

    if (!dataAtual) return null;

    switch (dataSource) {
        case 'servicos':
            return {
                labels: dataAtual.servicos.map(s => s.nome),
                data: dataAtual.servicos.map(s => s.faturamento)
            };
        
        case 'formas_pagamento':
            return {
                labels: dataAtual.formas_pagamento.map(f => f.nome),
                data: dataAtual.formas_pagamento.map(f => f.valor)
            };
        
        case 'faturamento_mes':
            // Compilar faturamento de todos os meses
            const meses = Object.keys(currentClient.data);
            const faturamentos = meses.map(mes => currentClient.data[mes].faturamento);
            return {
                labels: meses.map(m => m.charAt(0).toUpperCase() + m.slice(1)),
                data: faturamentos
            };
        
        case 'comparativo_faturamento':
            const mesesComparacao = Object.keys(currentClient.data);
            const idxAtual = mesesComparacao.indexOf(mesAtual);
            if (idxAtual === -1) return null;

            const labelsComparativo = [];
            const dataComparativo = [];

            if (idxAtual > 0) {
                const mesAnterior = mesesComparacao[idxAtual - 1];
                labelsComparativo.push(mesAnterior.charAt(0).toUpperCase() + mesAnterior.slice(1));
                dataComparativo.push(currentClient.data[mesAnterior].faturamento);
            }

            labelsComparativo.push(mesAtual.charAt(0).toUpperCase() + mesAtual.slice(1));
            dataComparativo.push(currentClient.data[mesAtual].faturamento);

            return {
                labels: labelsComparativo,
                data: dataComparativo
            };
        
        case 'ticket_medio_servico':
            // Calcular ticket médio por serviço
            // ticket = faturamento_serviço / quantidade_de_vendas_serviço
            // Estimamos a quantidade de vendas do serviço proporcionalmente
            const faturamentoTotal = dataAtual.faturamento;
            const vendasTotal = dataAtual.vendas;
            
            const ticketPorServico = dataAtual.servicos.map(s => {
                // Proporção de vendas do serviço em relação ao total
                const pctFaturamento = s.faturamento / faturamentoTotal;
                const vendasServico = Math.round(vendasTotal * pctFaturamento);
                const ticketMedio = vendasServico > 0 ? s.faturamento / vendasServico : 0;
                return {
                    nome: s.nome,
                    ticket: parseFloat(ticketMedio.toFixed(0))
                };
            });
            return {
                labels: ticketPorServico.map(s => s.nome),
                data: ticketPorServico.map(s => s.ticket)
            };

        case 'taxa_recorrencia':
            // Taxa de recorrência simulada por serviço
            const recorrencia = dataAtual.servicos.map((s, idx) => {
                const taxas = [78, 65, 72, 58, 85]; // taxas diferentes por serviço
                return {
                    nome: s.nome,
                    taxa: taxas[idx] || 70
                };
            });
            return {
                labels: recorrencia.map(s => s.nome),
                data: recorrencia.map(s => s.taxa)
            };
        
        case 'tamanho_animal':
            // Distribuição por tamanho de animal (petshop)
            const tamanhos = [
                { nome: 'Pequeno (até 5kg)', valor: 2800 },
                { nome: 'Médio (5-20kg)', valor: 3600 },
                { nome: 'Grande (20-40kg)', valor: 2200 },
                { nome: 'Gigante (40kg+)', valor: 900 }
            ];
            return {
                labels: tamanhos.map(t => t.nome),
                data: tamanhos.map(t => t.valor)
            };
        
        case 'clientes_novos_recorrentes':
            // Clientes novos vs recorrentes (petshop)
            const totalClientes = dataAtual.clientes;
            const taxaRetencao = 0.65; // 65% são recorrentes
            const recorrentes = Math.round(totalClientes * taxaRetencao);
            const novos = totalClientes - recorrentes;
            return {
                labels: ['Novos', 'Recorrentes'],
                data: [novos, recorrentes]
            };
        
        default:
            console.warn(`dataSource desconhecido: ${dataSource}`);
            return null;
    }
}

/**
 * Gera insights automáticos baseado no tipo de gráfico e dados
 */
function generateInsight(chartConfig, chartData, dataSource) {
    const tipo = currentClient.type;
    const mesAtual = document.getElementById('month-select').value;
    const dataAtual = currentClient.data[mesAtual];
    
    const insightMap = {
        'servicos': () => {
            if (tipo === 'salao_beleza') {
                const top = chartData.labels[0];
                const segundo = chartData.labels[1] || null;
                const base = `💡 ${top} foi o serviço que mais trouxe dinheiro esse mês.`;
                const dica = segundo
                    ? ` Oferecer ${top} junto com ${segundo} no mesmo dia pode aumentar o valor do atendimento sem precisar de uma cliente a mais.`
                    : ` Garanta que a agenda sempre tenha horários vagos pra ele, especialmente nas sextas e sábados.`;
                return base + dica;
            } else if (tipo === 'petshop') {
                const top = chartData.labels[0];
                return `💡 ${top} é estrela do mês. Aumente agendamentos nos dias vazios.`;
            }
        },
        'formas_pagamento': () => {
            const topPagamento = chartData.labels[0];
            const totalValor = chartData.data.reduce((a, b) => a + b, 0);
            const porcentagem = Math.round((chartData.data[0] / totalValor) * 100);
            if (tipo === 'salao_beleza') {
                const temCartao = chartData.labels.some(l => l.toUpperCase().includes('CREDITO') || l.toUpperCase().includes('CRÉDITO') || l.toUpperCase().includes('DEBITO') || l.toUpperCase().includes('DÉBITO'));
                const dicaExtra = temCartao
                    ? ` Cartão tem taxa — se puder oferecer um desconto de R$ 5 pra quem pagar no PIX, você economiza na maquininha e a cliente ainda sente que ganhou algo.`
                    : ` PIX é ótimo: cai na hora, sem taxa, sem esperar. Deixe o QR code sempre visível na recepção.`;
                return `💡 ${porcentagem}% das suas clientes pagam com ${topPagamento}.${dicaExtra}`;
            } else {
                return `💡 ${topPagamento} favorito (${porcentagem}%). Facilite pagamentos = mais vendas.`;
            }
        },
        'faturamento_mes': () => {
            const variacao = dataAtual.changeFaturamento;
            if (tipo === 'salao_beleza') {
                if (variacao > 0) {
                    return `💡 Você faturou ${variacao.toFixed(1)}% a mais que o mês passado — ótima fase! Tente lembrar o que fez diferente esse mês: mais agendamentos, alguma promoção, um serviço novo? Repetir isso nos próximos meses é o caminho pra continuar crescendo.`;
                } else if (variacao < 0) {
                    return `💡 Esse mês veio ${Math.abs(variacao).toFixed(1)}% abaixo do anterior. Pode ser época mais fraca mesmo, mas vale mandar uma mensagem pra clientes que não aparecem há mais de 30 dias — um "saudade de você por aqui!" já traz muita gente de volta.`;
                } else {
                    return `💡 Faturamento igual ao mês passado. Estabilidade é bom sinal, mas uma promoção num dia fraco da semana pode ser o empurrão pra crescer.`;
                }
            }
            if (variacao > 0) {
                return `💡 Mês em alta! Crescimento ${variacao.toFixed(1)}%. Mantenha estratégia.`;
            } else if (variacao < 0) {
                return `💡 Queda ${Math.abs(variacao).toFixed(1)}%. Aumente promoções e reative clientes.`;
            } else {
                return `💡 Faturamento estável. Base sólida para crescimento.`;
            }
        },
        'comparativo_faturamento': () => {
            if (tipo === 'salao_beleza') {
                const vals = chartData.data;
                if (vals.length < 2) return `💡 Primeiro mês registrado. Os próximos vão mostrar como está a evolução.`;
                const anterior = vals[0];
                const atual = vals[vals.length - 1];
                const diff = atual - anterior;
                const pct = ((diff / anterior) * 100).toFixed(1);
                if (diff > 0) {
                    return `💡 Esse mês você faturou R$ ${diff.toLocaleString('pt-BR')} a mais que o anterior (+${pct}%). Cada real a mais vem de mais atendimentos ou de serviços de maior valor — continue nessa direção.`;
                } else if (diff < 0) {
                    return `💡 Esse mês ficou R$ ${Math.abs(diff).toLocaleString('pt-BR')} abaixo do anterior (${pct}%). Meses mais fracos acontecem — o mais importante é não deixar a agenda com buracos longos sem tentar preencher com retornos ou indicações.`;
                } else {
                    return `💡 Faturamento igual ao mês anterior. Consistência é boa — uma ação pequena como promoção relâmpago já pode mudar esse número no próximo mês.`;
                }
            }
            return 'Continue acompanhando.';
        },
        'ticket_medio_servico': () => {
            const tickets = chartData.data;
            const maior = Math.max(...tickets);
            const servico_maior = chartData.labels[tickets.indexOf(maior)];
            const menor = Math.min(...tickets);
            const servico_menor = chartData.labels[tickets.indexOf(menor)];
            if (tipo === 'salao_beleza') {
                return `💡 ${servico_maior} gera mais dinheiro por atendimento (R$ ${maior.toFixed(0)} por visita). ${servico_menor} traz só R$ ${menor.toFixed(0)} — mas se uma cliente vier fazer ${servico_menor} e você oferecer um complemento rápido, o valor da visita dela sobe bastante.`;
            }
            return `💡 ${servico_maior} maior valor por atendimento (R$ ${maior.toFixed(0)}). Promova junto com outros serviços.`;
        },
        'taxa_recorrencia': () => {
            const taxas = chartData.data;
            const media = (taxas.reduce((a, b) => a + b) / taxas.length).toFixed(0);
            if (tipo === 'salao_beleza') {
                const topIdx = taxas.indexOf(Math.max(...taxas));
                const topServico = chartData.labels[topIdx];
                return `💡 Em média, ${media}% das clientes de cada serviço voltam no mês seguinte. ${topServico} tem a melhor fidelidade — quem faz esse serviço costuma marcar de novo sem precisar ser lembrada. Mandar uma mensagem pra quem não voltou no último mês é a forma mais rápida de recuperar receita.`;
            }
            return `💡 Taxa média ${media}%. Reter 40% inativos = +50% faturamento.`;
        },
        'tamanho_animal': () => {
            const topSize = chartData.labels[0];
            return `💡 Maioria: ${topSize}. Ajuste agenda e estoque para demanda real.`;
        },
        'clientes_novos_recorrentes': () => {
            const dados = chartData.data;
            const pct_rec = Math.round((dados[1] / (dados[0] + dados[1])) * 100);
            if (pct_rec > 65) {
                return `💡 ${pct_rec}% retornam! Retenção excelente. Peça indicações.`;
            } else {
                return `💡 ${pct_rec}% retornam. Aumente follow-up com novos clientes.`;
            }
        }
    };
    
    return insightMap[dataSource] ? insightMap[dataSource]() : 'Continue acompanhando.';
}

/**
 * Cria configuração de gráfico baseado no tipo e data
 */
function createChartConfig(chartConfig, chartData) {
    const tema = currentClient;
    const corPrincipal = chartConfig.cor || tema.color_theme || 'rgba(59, 130, 246, 0.8)';
    const corPrincipalSolida = corPrincipal.replace('0.8', '1');

    const configBase = {
        type: chartConfig.tipo || 'bar',
        data: {
            labels: chartData.labels,
            datasets: [{
                label: chartConfig.titulo || 'Dados',
                data: chartData.data,
                borderColor: '#1e293b',
                borderWidth: chartConfig.tipo === 'doughnut' ? 2 : 0,
                borderRadius: 3
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            plugins: {
                legend: {
                    position: chartConfig.tipo === 'doughnut' ? 'bottom' : 'top',
                    labels: { color: '#cbd5e1', padding: 10 }
                }
            }
        }
    };

    // Customizar conforme tipo
    if (chartConfig.tipo === 'bar') {
        configBase.data.datasets[0].backgroundColor = corPrincipal;
        configBase.data.datasets[0].borderColor = corPrincipalSolida;
        const isHorizontal = chartConfig.posicao === 'esquerda';
        configBase.options.indexAxis = isHorizontal ? 'y' : 'x';
        configBase.options.scales = {
            x: {
                beginAtZero: true,
                ticks: { color: '#94a3b8' },
                grid: { color: 'rgba(51, 65, 85, 0.2)' }
            },
            y: {
                ticks: { color: '#94a3b8' },
                grid: { display: false }
            }
        };
        if (isHorizontal) {
            const temp = configBase.options.scales.x;
            configBase.options.scales.x = configBase.options.scales.y;
            configBase.options.scales.y = temp;
            configBase.options.maintainAspectRatio = false;
            configBase.options.scales.x.display = false;
            configBase.options.layout = { padding: { right: 80 } };
            configBase.plugins = [{
                id: 'barValueLabels',
                afterDatasetsDraw(chart) {
                    const { ctx } = chart;
                    chart.data.datasets.forEach((ds, i) => {
                        const meta = chart.getDatasetMeta(i);
                        meta.data.forEach((bar, idx) => {
                            const val = ds.data[idx];
                            if (val <= 0) return;
                            ctx.fillStyle = '#cbd5e1';
                            ctx.font = '11px -apple-system, BlinkMacSystemFont, sans-serif';
                            ctx.textAlign = 'left';
                            ctx.textBaseline = 'middle';
                            ctx.fillText('R$ ' + val.toLocaleString('pt-BR'), bar.x + 6, bar.y);
                        });
                    });
                }
            }];
        }
        configBase.options.plugins.legend.display = false;
    } else if (chartConfig.tipo === 'doughnut') {
        const cores = [corPrincipal, '#10b981', '#fbbf24', '#ef4444'];
        configBase.data.datasets[0].backgroundColor = cores.slice(0, chartData.labels.length);
    } else if (chartConfig.tipo === 'line') {
        configBase.data.datasets[0].borderColor = corPrincipalSolida;
        configBase.data.datasets[0].backgroundColor = corPrincipal.replace('0.8', '0.1');
        configBase.data.datasets[0].borderWidth = 2;
        configBase.data.datasets[0].fill = true;
        configBase.data.datasets[0].tension = 0.4;
        configBase.data.datasets[0].pointRadius = 0;
        configBase.data.datasets[0].pointHoverRadius = 5;
        configBase.options.scales = {
            y: { ticks: { color: '#94a3b8' }, grid: { color: 'rgba(51, 65, 85, 0.2)' } },
            x: { ticks: { color: '#94a3b8' }, grid: { display: false } }
        };
        configBase.options.plugins.legend.display = false;
    } else if (chartConfig.tipo === 'pie') {
        const cores = [corPrincipal, '#10b981', '#fbbf24', '#ef4444'];
        configBase.data.datasets[0].backgroundColor = cores.slice(0, chartData.labels.length);
    }

    return configBase;
}

// Data atual
function updateDate() {
    const lastUpdateEl = document.getElementById('lastUpdate');
    if (!lastUpdateEl) return;
    
    const options = { weekday: 'short', month: 'short', day: 'numeric' };
    const dateStr = new Date().toLocaleDateString('pt-BR', options);
    lastUpdateEl.textContent = 'Atualizado: ' + dateStr;
}
