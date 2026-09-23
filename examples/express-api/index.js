const express = require("express");
const app = express();
const port = 3000;

app.use(express.json());

// 1. Rota GET simples e rápida
app.get("/api/users", (req, res) => {
  res.json({
    message: "Lista de usuários",
    users: [
      { id: 1, name: "Alice" },
      { id: 2, name: "Bob" },
    ],
  });
});

// 2. Rota POST para testar envio de payload
app.post("/api/users", (req, res) => {
  const { name } = req.body;
  res.status(201).json({
    message: "Usuário criado com sucesso",
    name,
  });
});

// 3. Rota com atraso simulado (ótimo para testar concorrência e timeouts)
app.get("/api/slow", (req, res) => {
  setTimeout(() => {
    res.json({ message: "Esta resposta foi lenta (2 segundos)" });
  }, 2000);
});

// 4. Rota que simula um erro 500
app.get("/api/error", (req, res) => {
  res.status(500).json({ error: "Erro interno do servidor simulado" });
});

// 5. Rota para CPU intensiva (simulado)
app.get("/api/cpu", (req, res) => {
  let result = 0;
  for (let i = 0; i < 100000000; i++) {
    result += i;
  }
  res.json({ message: "Processamento CPU intensivo concluído", result });
});

app.listen(port, () => {
  console.log(`API de testes rodando em http://localhost:${port}`);
});
