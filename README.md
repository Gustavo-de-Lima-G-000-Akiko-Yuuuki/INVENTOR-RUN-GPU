# INVENTOR-RUN-GPU
Projeto que roda e otimiza o inventor para rodar na GPU e evitar gargalos - automatizado
# 🎮 Rodar o Autodesk Inventor na GPU NVIDIA (RTX)

Guia + script para garantir que o **Inventor use a placa dedicada NVIDIA** neste
notebook, com aceleração de hardware ligada. Feito sob medida para a sua máquina.

> **Arquivos desta pasta (`X:\-Sistema-\GPU\`):**
> - `Configurar-GPU-Inventor.ps1` — diagnóstico + configuração automática (segura/reversível)
> - `LEIA-GPU.md` — este guia

---

## 🖥️ Seu hardware (detectado)

| Item | Valor |
|---|---|
| Notebook | **Dell G15 5530** (híbrido / NVIDIA Optimus) |
| GPU dedicada | **NVIDIA GeForce RTX 3050 6GB Laptop** (driver 32.0.16.1047, 05/2026) |
| GPU integrada | **Intel UHD (Raptor Lake)** — compõe a tela (1920px) |
| CPU | Intel Core **i5-13450HX** (10 núcleos / 16 threads) |
| RAM | ~24 GB |
| Inventor | **2024** (`C:\Program Files\Autodesk\Inventor 2024\Bin\Inventor.exe`) |

> 🔎 **Diagnóstico importante:** no `nvidia-smi`, o `Inventor.exe` **já aparece anexado à
> NVIDIA**, mas com uso baixo (~10%). Ou seja, ele *toca* a placa, mas a preferência de alto
> desempenho e a aceleração não estavam plenamente forçadas. É isso que vamos resolver.

---

## 🧠 Expectativa realista (leia antes)

- O Inventor **não faz a modelagem na GPU** — abrir peça, restringir, extrudar, recalcular é
  **CPU** (boa parte *single-thread*). Sua i5-13450HX dá conta bem disso.
- A **GPU acelera a parte gráfica**: Zoom/Orbit/Pan, sombras, reflexos, transparência, silhuetas,
  materiais avançados, vista em corte e o **Ray Tracing** (render realista). ([Autodesk][1])
- Portanto "rodar na GPU" = **a viewport 3D usar a RTX** e ela assumir os efeitos + ray tracing.
  Isso deixa o giro do modelo fluido e a renderização muito mais rápida.
- Sua RTX 3050 (GeForce) **funciona**, mas não é uma das placas **certificadas** pela Autodesk
  (a lista oficial foca em **RTX PRO / Quadro**). GeForce roda normalmente; só não tem selo. ([Autodesk][2])

---

## 🚀 Passo 1 — Rodar o script (faz o principal automaticamente)

No PowerShell (não precisa admin), dentro de `X:\-Sistema-\GPU\`:

```powershell
# se o Windows bloquear a execução do script uma única vez:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\Configurar-GPU-Inventor.ps1
```

O script vai:
1. Mostrar o **diagnóstico** (GPUs, driver, plano de energia, Inventor aberto?).
2. Gravar a **preferência de GPU do Windows** para o `Inventor.exe` = **Alto desempenho (NVIDIA)**
   — é o mesmo que *Configurações → Sistema → Vídeo → Gráficos*, só que automático (mexe só em `HKCU`).
3. Ativar o **plano de energia Alto desempenho**.
4. Abrir o **Painel NVIDIA** e a tela de **Gráficos do Windows** para os ajustes manuais abaixo.
5. **Verificar** com `nvidia-smi`.

Para **desfazer**: `.\Configurar-GPU-Inventor.ps1 -Reverter`

> ⚠️ **Feche e reabra o Inventor** depois de rodar — a preferência vale a partir do próximo início.

---

## 🖱️ Passo 2 — Painel de Controle NVIDIA (manual, 1 min)

O perfil por aplicativo do NVIDIA fica num arquivo binário e é melhor ajustar pela interface: ([NVIDIA][3])

1. Botão direito na área de trabalho → **Painel de Controle NVIDIA**.
2. **Gerenciar configurações 3D** → aba **Configurações de programa**.
3. Em *"Selecione um programa..."* → **Adicionar** → escolha **`Inventor.exe`**
   (`C:\Program Files\Autodesk\Inventor 2024\Bin\Inventor.exe`).
4. *"Selecione o processador gráfico preferido"* → **Processador NVIDIA de alto desempenho**.
5. (Recomendado) ainda nesse programa, ajuste:
   - **Modo de gerenciamento de energia** → *Prefira o desempenho máximo*.
   - **Threaded optimization / Otimização de threads** → *Ativado*.
6. **Aplicar**.

> Alternativa rápida (Optimus): botão direito no atalho do Inventor →
> **Executar com processador gráfico → Processador NVIDIA de alto desempenho**. ([NVIDIA][4])

---

## ⚙️ Passo 3 — Aba Hardware do Inventor (manual)

Dentro do Inventor: **Ferramentas → Opções do Aplicativo → aba Hardware**.
- Deixe a **aceleração de hardware / gráficos** ativada (evite "Software Graphics"/modo de compatibilidade,
  que ignora a GPU).
- Se houver escolha de adaptador, selecione a **NVIDIA**.
- Se a viewport piscar/artefatar, atualize o driver (Passo 5) antes de desligar a aceleração.

---

## 🎨 Passo 4 — Ray Tracing na GPU (render realista)

No Inventor 2023/2024, com placa suportada, dá para trocar o processador do **Ray Tracing de
CPU para GPU** (bem mais rápido para imagens realistas). ([Autodesk][5])
- Ative o modo de aparência realista / *Ray Tracing* e, nas opções, escolha **GPU**.

---

## 🔄 Passo 5 — Driver certo: NVIDIA Studio

Para apps profissionais (CAD), a NVIDIA recomenda o **Studio Driver** (mais estável para
criação) em vez do **Game Ready**:
- Baixe em **nvidia.com/drivers** (ou pelo **NVIDIA App**) e escolha **Studio Driver (SD)**.
- Reinicie após instalar. Depois confira a estabilidade da viewport no Inventor.

---

## 🔋 Passo 6 — Específico do Dell G15

- **Na tomada** sempre que for trabalhar (na bateria o Optimus reduz a NVIDIA para poupar energia).
- **Dell / Alienware — modo de desempenho ("G-Mode")**: ative para liberar o máximo de
  potência térmica da GPU/CPU (atalho geralmente **Fn + F9**, ou pelo app *Alienware/MyDell*).
- **BIOS**: se existir opção de *Advanced Optimus / gráficos discretos*, deixe no padrão
  (Optimus) — o que resolve é a preferência por-app, não desligar a Intel.

---

## ✅ Como confirmar que deu certo

1. Abra o Inventor e um modelo 3D; gire/dê zoom.
2. Rode no PowerShell:
   ```powershell
   nvidia-smi
   ```
   Procure o **`Inventor.exe`** na lista de processos e observe **GPU-Util subir** ao girar o modelo.
3. Opcional: `nvidia-smi dmon` (monitor contínuo) enquanto usa o Inventor.

> Sinal de sucesso: ao orbitar um conjunto grande, a coluna **GPU-Util** sobe (ex.: 30–90%),
> em vez de ficar quase parada.

---

## 🩺 Problemas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| Viewport travando/lenta | Inventor na Intel, ou aceleração desligada | Passos 1–3 |
| Tela pisca / artefatos | Driver desatualizado ou instável | Studio Driver (Passo 5) |
| NVIDIA "não faz nada" | Na bateria / economia de energia | Tomada + plano Alto desempenho + Passo 2 |
| Render (imagem) muito lento | Ray Tracing na CPU | Passo 4 (GPU) |
| Uso da GPU só sobe ao girar | **Normal** — modelagem é CPU | Nada a fazer; é o esperado |

---

## 📚 Fontes

- [1] Autodesk — *Graphics card usage in Inventor (quais recursos usam GPU)*: <https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Graphics-card-usage-in-Inventor.html>
- [2] Autodesk — *Inventor Certified Graphics Hardware*: <https://www.autodesk.com/support/system-requirements/certified-graphics-hardware/inventor>
- [3] NVIDIA — *Manage 3D Settings / Program Settings (perfis por aplicativo)*: <https://nvidia.custhelp.com/app/answers/detail/a_id/2615>
- [4] NVIDIA — *Using Optimus / escolher a GPU por aplicativo*: <https://www.nvidia.com/content/Control-Panel-Help/vLatest/en-gb/mergedProjects/nvcplENG/Using_Optimus_Hybrid.htm>
- [5] Autodesk Help — *GPU Ray Tracing (Inventor 2024)*: <https://help.autodesk.com/view/INVNTOR/2024/ENU/?guid=GUID-E203B7A4-B80D-4880-B234-67B9DB9F8358>
- Puget Systems — *Hardware Recommendations for Autodesk Inventor*: <https://www.pugetsystems.com/solutions/cad-workstations/autodesk-inventor/hardware-recommendations/>

*Guia gerado para Dell G15 5530 · RTX 3050 6GB · Inventor 2024.*
