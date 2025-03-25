# Dockerコンテナ作成について

## 事前準備
- [README](README.md)のSupported datasetsのシェルスクリプトを実行する
- [README](README.md)のEvaluation with pre-trained modelsの学習済みモデルのシェルスクリプトを実行する

## コンテナ作成手順
```
$ docker-compose up -d --build
$ docker-compose exec -u vscode pl2map bash
```
## コンテナ停止
```
$ docker-compose down
```

### 既存イメージを使用して実行する場合
```
$ docker-compose up -d
$ docker-compose exec -u vscode pl2map bash
```

## マウントの確認
```
$ ls -la /app/logs
$ ls -la /app/train_test_datasets
```

