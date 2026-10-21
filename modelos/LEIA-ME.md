# Modelo para cadastro de vários itens

Preencha `modelo_cadastro_itens.csv` no Excel ou LibreOffice. Use uma linha por produto e mantenha a primeira linha como cabeçalho.

| Coluna | Preenchimento |
|---|---|
| `nome` | Nome do produto, obrigatório. |
| `unidade` | Use `UN`, `GR` ou `ML`. |
| `quantidade_inicial` | Saldo inicial inteiro, zero ou maior. Use `0` se não houver saldo. |
| `valor_unitario` | Custo pago por unidade do item, em reais. Use `0` quando não souber ou não se aplicar. |
| `observacoes` | Informação opcional, como marca, fornecedor ou validade. |

Exemplo de linha: `Farinha de trigo;GR;5000;0,0065;Pacote de 5 kg`.

O arquivo é um modelo para organizar os dados. A tela atual do sistema não importa CSV e o formulário de produto não recebe custo inicial; para cadastrar vários itens com seus custos em uma operação, ainda é preciso adicionar uma função de importação em lote ao sistema.
