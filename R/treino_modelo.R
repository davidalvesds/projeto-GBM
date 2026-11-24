library(gbm)
library(pROC)
library(caret)
library(rpart)
library(mlr)
library(ROSE)
library(epiDisplay)
library(dplyr)

load("dados/dados_gbm.rda")

dados$sex     <- factor(dados$sex, levels = c('M', 'F'),labels = c(0,1)    )
dados$TenYearCHD <- factor(dados$TenYearCHD, levels = c(0,1))
dados$education     <- factor(dados$education, levels = c(1,2,3,4),labels = c(0,1,2,3)    )
dados$currentSmoker <- factor(dados$currentSmoker, levels = c(0,1))
dados$BPMeds <- factor(dados$BPMeds, levels = c(0,1))
dados$prevalentStroke <- factor(dados$prevalentStroke, levels = c(0,1))
dados$prevalentHyp <- factor(dados$prevalentHyp, levels = c(0,1))
dados$diabetes <- factor(dados$diabetes, levels = c(0,1))

dados
tab1(dados$TenYearCHD)

set.seed(118020008)
inTrain <- createDataPartition(dados$TenYearCHD,p=0.7,list=F)
treino <- dados[inTrain,]
teste <- dados[-inTrain,]

treino1 <- ROSE(TenYearCHD ~ ., data  = treino, p=.55)$data
tab1(treino1$TenYearCHD)

treino_imp = impute(treino1, target = "TenYearCHD",
                    classes = list(numeric = imputeLearner("regr.rpart"),
                                   factor = imputeLearner("classif.rpart")))

treino2= treino_imp$data

preprocessamento = preProcess(treino2,c("center","scale", "nzv"))
treino2= predict(preprocessamento, treino2)

tipo<-treino2$TenYearCHD==1
treino2<-dplyr::mutate(treino2,TenYearCHD=tipo)

ReNA = treino_imp$desc
teste_imp = reimpute(teste, ReNA)
teste_imp<-predict(preprocessamento,teste_imp)

tipot<-teste_imp$TenYearCHD==1
teste_imp<-mutate(teste_imp,TenYearCHD=tipot)

interaction.depth <- c(1, 3, 5)
shrinkage <- c(0.05, 0.1, 0.5)
ntree <- 1000

cv_gbm <- function(treino, teste, interaction.depth, shrinkage, ntree) {
  resumo <- matrix(ncol = 6, nrow = length(interaction.depth) * length(shrinkage),
                   dimnames = list(NULL, c("interaction.depth", "shrinkage", "Acuracia", "Sensibilidade", "Especificidade", "AUC")))
  set.seed(118020008)
  for (i in 1:length(interaction.depth)) {
    depth <- interaction.depth[i]
    for (j in 1:length(shrinkage)) {
      shrink <- shrinkage[j]
      index <- (i - 1) * length(shrinkage) + j

      modelFit <- gbm::gbm(formula = TenYearCHD ~ .,
                           data = treino,
                           distribution = "bernoulli",
                           n.trees = ntree,
                           interaction.depth = depth,
                           shrinkage = shrink,
                           bag.fraction = 1,
                           cv.folds = 5)

      a <- gbm.perf(modelFit)

      otimizador <- function(predicao, resposta) {
        require(ROCR)
        predicao2 <- prediction(predicao, resposta)
        performance <- performance(predicao2, "tpr", "fpr")
        funcao <- attr(performance, "y.values")[[1]] - attr(performance, "x.values")[[1]]
        c <-  performance@alpha.values[[1]][which.max(funcao)]
        plot(performance, colorize = TRUE, lwd = 2)
        c
      }

      predicao_treino <- predict(modelFit, treino, type = 'response', n.trees = a)
      c <- otimizador(predicao_treino, treino$TenYearCHD)

      predicao <- predict(modelFit, teste, type = 'response', n.trees = a)
      classificacao2 <- predicao >= c

      metrics <- confusionMatrix(data = as.factor(classificacao2), reference = as.factor(teste$TenYearCHD))

      resumo[index, ] <- c(depth, shrink, metrics$overall[1], metrics$byClass[1], metrics$byClass[2], metrics$byClass[3])
    }
  }

  return(list("Resultado_nos_folds" = resumo))
}

cv_gbm(treino2, teste_imp, interaction.depth, shrinkage, ntree)

set.seed(118020008)
modelFit1<-gbm(TenYearCHD~.,data=treino2,
               distribution="bernoulli",
               n.trees = 1000,
               interaction.depth = 3,
               shrinkage=0.10,
               bag.fraction =1,
               cv.fold=5)

head(summary(modelFit1))

a=gbm.perf(modelFit1)
a

otimizador<-function(predicao,resposta){
  require(ROCR)
  predicao2 = prediction(predicao, resposta)
  performance = performance(predicao2,"tpr","fpr")
  funcao <- attr(performance, "y.values")[[1]] -
    (attr(performance, "x.values")[[1]])
  c <-  performance@alpha.values[[1]][which.max(funcao)]
  plot(performance, colorize=T, lwd=2)
  c
}

predicao_treino<-predict(modelFit1,treino2,
                         type = 'response',
                         n.trees=a)

c<-otimizador(predicao_treino,treino2$TenYearCHD)

predicao<-predict(modelFit1,teste_imp,
                  type = 'response',
                  n.trees=a)

classificacao2<-predicao>=c

confusionMatrix(data=as.factor(classificacao2),
                reference=as.factor(teste_imp$TenYearCHD))

save(preprocessamento, modelFit1, ReNA, c, a ,file="modelo/modelo_risco_cardiaco.Rdata")
