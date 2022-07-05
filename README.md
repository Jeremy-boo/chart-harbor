# Helm Chart for Harbor

## 介绍

This [Helm](https://github.com/kubernetes/helm) chart installs Harbor in a Kubernetes cluster.

此 chart 定义了如下组件：

- portal
- core
- registry
- trivy
- jobservice
- notary
- chartmuseum
- database
- redis

## 环境要求

- Kubernetes 1.10 及以上版本、Beta APIs
- Kubernetes Ingress Controller
- Helm 2.8.0 及以上版本

## 安装 Chart

要安装版本名为 "harbor" 的 chart, 请在 Kubernetes 集群的 master 节点中运行:

```
helm install --name harbor --namespace <namespace> --set externalDomain=core.harbor.domain .
```

> **Tip**: 使用 `helm list` 列出所有版本

## 卸载 Chart

卸载/删除 `harbor`:

```
helm delete --purge harbor
```

该命令将删除与 `chart` 关联的所有 `Kubernetes` 资源并删除该版本. 

## 配置

可以到 `values.yaml` 中查看所有配置的默认值, 使用 `helm install` 的 `--set key=value[,key=value]` 参数设置每个参数.

或者, 可以在安装 `chart` 时提供指定参数值的 `YAML` 文件. 例如:

```
helm install --name harbor -f values.yaml .
```

## 镜像地址

在一个私有的网络环境，连接到外网会受限制，所以需要使用本地的镜像仓库。当指定镜像仓库地址时，如果指定一个 IP 地址为 `10.0.0.2`，并可以访问的镜像仓库地址，运行命令：

```
--set global.registry.address=10.0.0.2
```

## 数据存储

在安装 chart 前，请先确认将用哪种方式来存储数据:
 
1. Persistent Volume Claim (建议)
2. Host path

### Persistent Volume Claim (PVC)

如果 k8s 集群已经有可用的 StorageClass 和 provisioner，在安装 chart 过程中会自动创建 pvc 来存储数据。
想了解更多关于 StorageClass 和 PVC 的内容，可以参考 [Kubernetes Documentation](https://kubernetes.io/docs/concepts/storage/storage-classes/)

*harbor 中有 `database、redis、chartmuseum、registry、jobservice` 有数据的产生，下面只以 database 的配置为例说明，其它类似。*

**在部署过程中创建 PVC**

```
--set persistence.enabled=true \
--set persistence.persistentVolumeClaim.database.storageClass=default \
```

*storageClass 如果没有传，默认为 default*

**使用一个已存在的 PVC**

```
--set persistence.enabled=true \
--set persistence.persistentVolumeClaim.database.existingClaim=<pvc name> \
...
```

### 主机路径

如果集群中没有 provision, 可以用如下方式替代:

**存储数据到当前 node 中**

```
--set persistence.enabled=false \
--set persistence.hostPath.database.host.nodeName=<node name> \
--set persistence.hostPath.database.host.path=<path on host to store data>
```

## 访问方式

### 通过 ip 访问

部署 gitlab 时候，需要确定 gitlab 的访问方式, 如果没有可用的域名，也可以通过 `<nodeIP>:<nodePort>` 的方式来访问，示例如下：

```
helm install . --name harbor --namespace default \
--set externalURL=http://${nodeIP}:${nodePort} \
--set harborAdminPassword=Harbor12345 \
--set expose.type=nodePort \
--set expose.nodePort.ports.http.nodePort=${nodePort} \
...
```

nodePort 的值应该在 `30000` 到 `32767` 中间取值，不要与集群其它服务端口冲突。

### 通过域名访问

```
helm install . --name harbor --namespace default \
--set externalURL=https://harbor.${DOMAIN} \
--set harborAdminPassword=Harbor12345 \
--set expose.type=ingress \
--set expose.ingress.hosts.core=harbor.${DOMAIN} \
--set expose.ingress.hosts.notary=notary.${DOMAIN} \
```

## 日志级别设置

harbor可选的日志等级有 可选值有  debug   info  warning  error  fatal

通过chart部署时，可以通过设置 --set logLevel 的值 来决定使用什么级别的日志  默认info级别

部署后，如果需要修改 则需要通过修改 configmap ${releasename}-harbor-core, 将 LOG_LEVEL 设置为需要的级别, 之后再重建deploy ${releasename}-harbor-core pod即可

## Changelog
官方：https://github.com/goharbor/harbor/blob/master/CHANGELOG.md、https://github.com/goharbor/harbor-helm/releases、https://github.com/goharbor/harbor/releases

## 补充说明
对于从1.8版本的harbor升级，由于chart参数结构有了比较大的调整，所以建议使用以下两种方式升级
1. 对于已经做了持久化操作的，可执行helm delete --purge harbor将之前的版本删除，并且参照当前chart的参数配置将原来的配置同步设置到新的版本中，重新执行helm install。
2. 对于想直接使用helm upgrade的用户，也同样需要在安装时将旧配置同步到当前chart的参数中，并且在执行时需带上--force --recreate-pods参数，例如：`helm upgrade harbor stable/harbor --force --recreate-pods --set expose.type=nodePort ...`

## SSO 使用及配置
设置 harbor 实现 SSO 功能，需要增加以下配置


| 参数名称                  | 描述                        | 
| -----------------------    | ---------------------------------- | 
| `oidc.enable`       | 是否打开 oidc 功能 | 
| `oidc.clientID`  | OIDC 提供方 clientID | 
| `oidc.clientSecret` | OIDC 提供方 clientSccret | 
| `oidc.issuer` | OIDC 提供方地址 | 
| `oidc.scope`       | 授权访问用户的详细信息 | 
| `oidc.serverURL`       | Harbor 地址 | 
| `oidc.verifyCert`       | 是否验证证书 | 
| `oidc.harbor.mode`       | 认证模式 必须为 oidc_auth |
| `oidc.harbor.oidcName`       | OIDC 提供方名称 | 

示例
```
    --set oidc.enable=true \
    --set oidc.clientID=alauda \
    --set oidc.clientSecret=XXXXXXXXXXXXXXXXXX \
    --set oidc.issuer=https://192.168.16.71/dex \
    --set oidc.scope="openid\,profile\,offline_access\,groups\,email" \
    --set oidc.serverURL=192.xxx.xxx.xx:31120 \
    --set oidc.verifyCert=false \
    --set oidc.harbor.mode=oidc_auth \
    --set oidc.harbor.oidcName=some-dex \
```
[参数含义](https://goharbor.io/docs/1.10/administration/configure-authentication/oidc-auth/) 

### 判断是否正常
* 配置成功，在登录页面会提示 `通过OIDC提供商登录`，通过该选项登录，跳转到 OIDC 提供商登录地址，输入用户名密码，可以跳转回harbor平台即可

### 注意事项
* 如果 harbor 之前使用数据库模式增加过用户，那么 harbor 将不能再转换为 oidc 模式，详情请见[官方文档](https://goharbor.io/docs/1.10/administration/configure-authentication/oidc-auth/)
* 如果 harbor 开启了 oidc SSO 认证，那么管理员将不能再手动进行 harbor 用户的增加，用户只能通过 oidc 登录 harbor。造成的后果是如果用户想要将 harbor 集成到 ACP Devops 中，则只能使用admin的账号来集成
* 如果之前使用过 Auth 来设置过 SSO 配置，那在升级之前，需要先将job harbor-oidc 删除，再进行升级，并且升级过程中不允许再通过任何方式设置 Auth 的值

### 问题排查
* 如果发现登录错误，可以查看harbor-core的pod日志，如果报错含有SSL问题，查看是否 oidc.verifyCert 设置为false
* harbor的 oidc 是通过job启动pod向harbor发送了一个请求来完成的，所以如果oidc出现问题，可以先查看相关job harbor-oidc 的日志和记录找出原因

## 其它配置

下面的表格列出了 harbor chart 中的配置字段，以及它们的默认值。详细参数可参考values.yaml。

| 参数名称                  | 描述                        | 默认值                 |
| -----------------------    | ---------------------------------- | ----------------------- |
| **Expose**                                                                  |
| `expose.type`                                                               | The way how to expose the service: `ingress`, `clusterIP`, `nodePort` or `loadBalancer`, other values will be ignored and the creation of service will be skipped.                                                                                                                                                                                                                                                                         | `nodePort`                       |
| `expose.tls.enabled`                                                        | Enable the tls or not                                                                                                                                                                                                                                                                                                                           | `false`                          |
| `expose.ingress.controller` | The ingress controller type. Currently supports `default`, `gce` and `ncp` | `default` |
| `expose.tls.secretName` | Fill the name of secret if you want to use your own TLS certificate. The secret contains keys named: `tls.crt` - the certificate (required), `tls.key` - the private key (required), `ca.crt` - the certificate of CA (optional), this enables the download link on portal to download the certificate of CA. These files will be generated automatically if the `secretName` is not set | |
| `expose.tls.notarySecretName`                                               | By default, the Notary service will use the same cert and key as described above. Fill the name of secret if you want to use a separated one. Only needed when the `expose.type` is `ingress`.                                                                                                                                                  |                                 |
| `expose.tls.commonName`                                                     | The common name used to generate the certificate, it's necessary when the `expose.type` is `clusterIP` or `nodePort` and `expose.tls.secretName` is null                                                                                                                                                                                        |                                 |
| `expose.ingress.hosts.core`                                                 | The host of Harbor core service in ingress rule                                                                                                                                                                                                                                                                                                 | `core.harbor.domain`            |
| `expose.ingress.hosts.notary`                                               | The host of Harbor Notary service in ingress rule                                                                                                                                                                                                                                                                                               | `notary.harbor.domain`          |
| `expose.ingress.annotations`                                                | The annotations used in ingress                                                                                                                                                                                                                                                                                                                 |                                 |
| `expose.clusterIP.name`                                                     | The name of ClusterIP service                                                                                                                                                                                                                                                                                                                   | `harbor`                        |
| `expose.clusterIP.ports.httpPort`                                           | The service port Harbor listens on when serving with HTTP                                                                                                                                                                                                                                                                                       | `80`                            |
| `expose.clusterIP.ports.httpsPort`                                          | The service port Harbor listens on when serving with HTTPS                                                                                                                                                                                                                                                                                      | `443`                           |
| `expose.clusterIP.ports.notaryPort`                                         | The service port Notary listens on. Only needed when `notary.enabled` is set to `true`                                                                                                                                                                                                                                                          | `4443`                          |
| `expose.nodePort.name`                                                      | The name of NodePort service                                                                                                                                                                                                                                                                                                                    | `harbor`                        |
| `expose.nodePort.ports.http.port`                                           | The service port Harbor listens on when serving with HTTP                                                                                                                                                                                                                                                                                       | `80`                            |
| `expose.nodePort.ports.http.nodePort`                                       | The node port Harbor listens on when serving with HTTP                                                                                                                                                                                                                                                                                          | `31104`                         |
| `expose.nodePort.ports.https.port`                                          | The service port Harbor listens on when serving with HTTPS                                                                                                                                                                                                                                                                                      | `443`                           |
| `expose.nodePort.ports.https.nodePort`                                      | The node port Harbor listens on when serving with HTTPS                                                                                                                                                                                                                                                                                         | `31105`                         |
| `expose.nodePort.ports.notary.port`                                         | The service port Notary listens on. Only needed when `notary.enabled` is set to `true`                                                                                                                                                                                                                                                          | `4443`                          |
| `expose.nodePort.ports.notary.nodePort`                                     | The node port Notary listens on. Only needed when `notary.enabled` is set to `true`                                                                                                                                                                                                                                                             | `31106`                         |
| `expose.loadBalancer.name` | The name of service |`harbor`|
| `expose.loadBalancer.IP` | The IP of the loadBalancer.  It works only when loadBalancer support assigning IP |`""`|
| `expose.loadBalancer.ports.httpPort` | The service port Harbor listens on when serving with HTTP |`80`|
| `expose.loadBalancer.ports.httpsPort` | The service port Harbor listens on when serving with HTTP |`30002`|
| `expose.loadBalancer.ports.notaryPort` | The service port Notary listens on. Only needed when `notary.enabled` is set to `true`|
| `expose.loadBalancer.annotations` | The annotations attached to the loadBalancer service | {} |
| `expose.loadBalancer.sourceRanges` | List of IP address ranges to assign to loadBalancerSourceRanges | [] |
| **Internal TLS** |
| `internalTLS.enabled` | Enable the tls for the components (chartmuseum, clair, core, jobservice, portal, registry, trivy) | `false` |
| `internalTLS.certSource` | Method to provide tls for the components, options is `auto`, `manual`, `secret`. | `auto` |
| `internalTLS.trustCa` | The content of trust ca, only available when `certSrouce` is `manual`. **Note**: all the internal certificates of the components must be issued by this ca |  |
| `internalTLS.core.secretName` | The secret name for core component, only available when `certSource` is `secret`. The secret must contain keys named: `ca.crt` - the certificate of CA which is used to issue internal key and crt pair for components and all Harbor components must issued by the same CA , `tls.crt` - the content of the TLS cert file, `tls.key` - the content of the TLS key file. | |
| `internalTLS.core.crt` | Content of core's TLS cert file, only available when `certSource` is `manual` | |
| `internalTLS.core.key` | Content of core's TLS key file, only available when `certSource` is `manual` | |
| `internalTLS.jobservice.secretName` | The secret name for jobservice component, only available when `certSource` is `secret`. The secret must contain keys named: `ca.crt` - the certificate of CA which is used to issue internal key and crt pair for components and all Harbor components must issued by the same CA , `tls.crt` - the content of the TLS cert file, `tls.key` - the content of the TLS key file. | |
| `internalTLS.jobservice.crt` | Content of jobservice's TLS cert file, only available when `certSource` is `manual` | |
| `internalTLS.jobservice.key` | Content of jobservice's TLS key file, only available when `certSource` is `manual` | |
| `internalTLS.registry.secretName` | The secret name for registry component, only available when `certSource` is `secret`. The secret must contain keys named: `ca.crt` - the certificate of CA which is used to issue internal key and crt pair for components and all Harbor components must issued by the same CA , `tls.crt` - the content of the TLS cert file, `tls.key` - the content of the TLS key file. | |
| `internalTLS.registry.crt` | Content of registry's TLS cert file, only available when `certSource` is `manual` | |
| `internalTLS.registry.key` | Content of registry's TLS key file, only available when `certSource` is `manual` | |
| `internalTLS.portal.secretName` | The secret name for portal component, only available when `certSource` is `secret`. The secret must contain keys named: `ca.crt` - the certificate of CA which is used to issue internal key and crt pair for components and all Harbor components must issued by the same CA , `tls.crt` - the content of the TLS cert file, `tls.key` - the content of the TLS key file. | |
| `internalTLS.portal.crt` | Content of portal's TLS cert file, only available when `certSource` is `manual` | |
| `internalTLS.portal.key` | Content of portal's TLS key file, only available when `certSource` is `manual` | |
| `internalTLS.chartmuseum.secretName` | The secret name for chartmuseum component, only available when `certSource` is `secret`. The secret must contain keys named: `ca.crt` - the certificate of CA which is used to issue internal key and crt pair for components and all Harbor components must issued by the same CA , `tls.crt` - the content of the TLS cert file, `tls.key` - the content of the TLS key file. | |
| `internalTLS.chartmuseum.crt` | Content of chartmuseum's TLS cert file, only available when `certSource` is `manual` | |
| `internalTLS.chartmuseum.key` | Content of chartmuseum's TLS key file, only available when `certSource` is `manual` | |
| `internalTLS.clair.secretName` | The secret name for clair component, only available when `certSource` is `secret`. The secret must contain keys named: `ca.crt` - the certificate of CA which is used to issue internal key and crt pair for components and all Harbor components must issued by the same CA , `tls.crt` - the content of the TLS cert file, `tls.key` - the content of the TLS key file. | |
| `internalTLS.clair.crt` | Content of clair's TLS cert file, only available when `certSource` is `manual` | |
| `internalTLS.clair.key` | Content of clair's TLS key file, only available when `certSource` is `manual` | |
| `internalTLS.trivy.secretName` | The secret name for trivy component, only available when `certSource` is `secret`. The secret must contain keys named: `ca.crt` - the certificate of CA which is used to issue internal key and crt pair for components and all Harbor components must issued by the same CA , `tls.crt` - the content of the TLS cert file, `tls.key` - the content of the TLS key file. | |
| `internalTLS.trivy.crt` | Content of trivy's TLS cert file, only available when `certSource` is `manual` | |
| `internalTLS.trivy.key` | Content of trivy's TLS key file, only available when `certSource` is `manual` | |
| **Persistence**                                                             |
| `persistence.enabled`                                                       | Enable the data persistence or not                                                                                                                                                                                                                                                                                                              | `false`                          |
| `persistence.resourcePolicy`                                                | Setting it to `keep` to avoid removing PVCs during a helm delete operation. Leaving it empty will delete PVCs after the chart deleted                                                                                                                                                                                                           | `keep`                          |
| `persistence.persistentVolumeClaim.registry.existingClaim`                  | Use the existing PVC which must be created manually before bound, and specify the `subPath` if the PVC is shared with other components                                                                                                                                                                                                                                                                                |                                 |
| `persistence.persistentVolumeClaim.registry.storageClass`                   | Specify the `storageClass` used to provision the volume. Or the default StorageClass will be used(the default). Set it to `-` to disable dynamic provisioning                                                                                                                                                                                   |                                 |
| `persistence.persistentVolumeClaim.registry.subPath`                        | The sub path used in the volume                                                                                                                                                                                                                                                                                                                 |                                 |
| `persistence.persistentVolumeClaim.registry.accessMode`                     | The access mode of the volume                                                                                                                                                                                                                                                                                                                   | `ReadWriteOnce`                 |
| `persistence.persistentVolumeClaim.registry.size`                           | The size of the volume                                                                                                                                                                                                                                                                                                                          | `5Gi`                           |
| `persistence.persistentVolumeClaim.chartmuseum.existingClaim`               | Use the existing PVC which must be created manually before bound, and specify the `subPath` if the PVC is shared with other components                                                                                                                                                                                                                                                                                |                                 |
| `persistence.persistentVolumeClaim.chartmuseum.storageClass`                | Specify the `storageClass` used to provision the volume. Or the default StorageClass will be used(the default). Set it to `-` to disable dynamic provisioning                                                                                                                                                                                   |                                 |
| `persistence.persistentVolumeClaim.chartmuseum.subPath`                     | The sub path used in the volume                                                                                                                                                                                                                                                                                                                 |                                 |
| `persistence.persistentVolumeClaim.chartmuseum.accessMode`                  | The access mode of the volume                                                                                                                                                                                                                                                                                                                   | `ReadWriteOnce`                 |
| `persistence.persistentVolumeClaim.chartmuseum.size`                        | The size of the volume                                                                                                                                                                                                                                                                                                                          | `5Gi`                           |
| `persistence.persistentVolumeClaim.jobservice.existingClaim`                | Use the existing PVC which must be created manually before bound, and specify the `subPath` if the PVC is shared with other components                                                                                                                                                                                                                                                                                |                                 |
| `persistence.persistentVolumeClaim.jobservice.storageClass`                 | Specify the `storageClass` used to provision the volume. Or the default StorageClass will be used(the default). Set it to `-` to disable dynamic provisioning                                                                                                                                                                                   |                                 |
| `persistence.persistentVolumeClaim.jobservice.subPath`                      | The sub path used in the volume                                                                                                                                                                                                                                                                                                                 |                                 |
| `persistence.persistentVolumeClaim.jobservice.accessMode`                   | The access mode of the volume                                                                                                                                                                                                                                                                                                                   | `ReadWriteOnce`                 |
| `persistence.persistentVolumeClaim.jobservice.size`                         | The size of the volume                                                                                                                                                                                                                                                                                                                          | `1Gi`                           |
| `persistence.persistentVolumeClaim.database.existingClaim`                  | Use the existing PVC which must be created manually before bound, and specify the `subPath` if the PVC is shared with other components. If external database is used, the setting will be ignored                                                                                                                                                                                                                     |                                 |
| `persistence.persistentVolumeClaim.database.storageClass`                   | Specify the `storageClass` used to provision the volume. Or the default StorageClass will be used(the default). Set it to `-` to disable dynamic provisioning. If external database is used, the setting will be ignored                                                                                                                        |                                 |
| `persistence.persistentVolumeClaim.database.subPath`                        | The sub path used in the volume. If external database is used, the setting will be ignored                                                                                                                                                                                                                                                      |                                 |
| `persistence.persistentVolumeClaim.database.accessMode`                     | The access mode of the volume. If external database is used, the setting will be ignored                                                                                                                                                                                                                                                        | `ReadWriteOnce`                 |
| `persistence.persistentVolumeClaim.database.size`                           | The size of the volume. If external database is used, the setting will be ignored                                                                                                                                                                                                                                                               | `1Gi`                           |
| `persistence.persistentVolumeClaim.redis.existingClaim`                     | Use the existing PVC which must be created manually before bound, and specify the `subPath` if the PVC is shared with other components. If external Redis is used, the setting will be ignored                                                                                                                                                                                                                        |                                 |
| `persistence.persistentVolumeClaim.redis.storageClass`                      | Specify the `storageClass` used to provision the volume. Or the default StorageClass will be used(the default). Set it to `-` to disable dynamic provisioning. If external Redis is used, the setting will be ignored                                                                                                                           |                                 |
| `persistence.persistentVolumeClaim.redis.subPath`                           | The sub path used in the volume. If external Redis is used, the setting will be ignored                                                                                                                                                                                                                                                         |                                 |
| `persistence.persistentVolumeClaim.redis.accessMode`                        | The access mode of the volume. If external Redis is used, the setting will be ignored                                                                                                                                                                                                                                                           | `ReadWriteOnce`                 |
| `persistence.persistentVolumeClaim.redis.size`                              | The size of the volume. If external Redis is used, the setting will be ignored                                                                                                                                                                                                                                                                  | `1Gi`                           |
| `persistence.imageChartStorage.disableredirect`                             | The configuration for managing redirects from content backends. For backends which not supported it (such as using minio for `s3` storage type), please set it to `true` to disable redirects. Refer to the [guide](https://github.com/docker/distribution/blob/master/docs/configuration.md#redirect) for more information about the detail    | `false`                         |
| `persistence.imageChartStorage.caBundleSecretName` | Specify the `caBundleSecretName` if the storage service uses a self-signed certificate. The secret must contain keys named `ca.crt` which will be injected into the trust store  of registry's and chartmuseum's containers. | |
| `persistence.imageChartStorage.type`                                        | The type of storage for images and charts: `filesystem`, `azure`, `gcs`, `s3`, `swift` or `oss`. The type must be `filesystem` if you want to use persistent volumes for registry and chartmuseum. Refer to the [guide](https://github.com/docker/distribution/blob/master/docs/configuration.md#storage) for more information about the detail | `filesystem`                    |
| **General**                                                                 |
| `externalURL`                                                               | The external URL for Harbor core service                                                                                                                                                                                                                                                                                                        | `https://core.harbor.domain`    |
| `uaaSecretName` | If using external UAA auth which has a self signed cert, you can provide a pre-created secret containing it under the key `ca.crt`. | `` |
| `imagePullPolicy` | The image pull policy |  |
| `imagePullSecrets` | The imagePullSecrets names for all deployments |  |
| `updateStrategy.type` | The update strategy for deployments with persistent volumes(jobservice, registry and chartmuseum): `RollingUpdate` or `Recreate`. Set it as `Recreate` when `RWM` for volumes isn't supported  | `RollingUpdate` |
| `logLevel` | The log level: `debug`, `info`, `warning`, `error` or `fatal` | `info` |
| `harborAdminPassword`                                                       | The initial password of Harbor admin. Change it from portal after launching Harbor                                                                                                                                                                                                                                                              | `Harbor12345`                   |
| `secretkey`                                                                 | The key used for encryption. Must be a string of 16 chars                                                                                                                                                                                                                                                                                       | `not-a-secure-key`              |
| `proxy.httpProxy` | The URL of the HTTP proxy server | |
| `proxy.httpsProxy` | The URL of the HTTPS proxy server | |
| `proxy.noProxy` | The URLs that the proxy settings not apply to | 127.0.0.1,localhost,.local,.internal |
| `proxy.components` | The component list that the proxy settings apply to | core, jobservice, clair |
| **Nginx** (if expose the service via `ingress`, the Nginx will not be used) |
| `nginx.image.repository`                                                    | Image repository                                                                                                                                                                                                                                                                                                                                | `goharbor/nginx-photon`         |
| `nginx.image.tag`                                                           | Image tag                                                                                                                                                                                                                                                                                                                                       | `dev`                           |
| `nginx.replicas`                                                            | The replica count                                                                                                                                                                                                                                                                                                                               | `1`                             |
| `nginx.resources`                                                           | The [resources] to allocate for container                                                                                                                                                                                                                                                                                                       | undefined                       |
| `nginx.nodeSelector`                                                        | Node labels for pod assignment                                                                                                                                                                                                                                                                                                                  | `{}`                            |
| `nginx.tolerations`                                                         | Tolerations for pod assignment                                                                                                                                                                                                                                                                                                                  | `[]`                            |
| `nginx.affinity`                                                            | Node/Pod affinities                                                                                                                                                                                                                                                                                                                             | `{}`                            |
| `nginx.podAnnotations`                                                      | Annotations to add to the nginx pod                                                                                                                                                                                                                                                                                                             | `{}`                            |
| **Portal**                                                                  |
| `portal.image.repository`                                                   | Repository for portal image                                                                                                                                                                                                                                                                                                                     | `goharbor/harbor-portal`        |
| `portal.image.tag`                                                          | Tag for portal image                                                                                                                                                                                                                                                                                                                            | `dev`                           |
| `portal.replicas`                                                           | The replica count                                                                                                                                                                                                                                                                                                                               | `1`                             |
| `portal.resources`                                                          | The [resources] to allocate for container                                                                                                                                                                                                                                                                                                       | undefined                       |
| `portal.nodeSelector`                                                       | Node labels for pod assignment                                                                                                                                                                                                                                                                                                                  | `{}`                            |
| `portal.tolerations`                                                        | Tolerations for pod assignment                                                                                                                                                                                                                                                                                                                  | `[]`                            |
| `portal.affinity`                                                           | Node/Pod affinities                                                                                                                                                                                                                                                                                                                             | `{}`                            |
| `portal.podAnnotations`                                                     | Annotations to add to the portal pod                                                                                                                                                                                                                                                                                                            | `{}`                            |
| **Core** |
| `core.image.repository` | Repository for Harbor core image | `goharbor/harbor-core` |
| `core.image.tag` | Tag for Harbor core image | `dev` |
| `core.replicas` | The replica count  | `1` |
| `core.livenessProbe.initialDelaySeconds` | The initial delay in seconds for the liveness probe | `300` |
| `core.resources` | The [resources] to allocate for container | undefined |
| `core.nodeSelector`  | Node labels for pod assignment | `{}` |
| `core.tolerations` | Tolerations for pod assignment | `[]` |
| `core.affinity` | Node/Pod affinities | `{}` |
| `core.podAnnotations` | Annotations to add to the core pod | `{}` |
| `core.secret` | Secret is used when core server communicates with other components. If a secret key is not specified, Helm will generate one. Must be a string of 16 chars. | |
| `core.secretName` | Fill the name of a kubernetes secret if you want to use your own TLS certificate and private key for token encryption/decryption. The secret must contain keys named: `tls.crt` - the certificate and `tls.key` - the private key. The default key pair will be used if it isn't set | |
| `core.xsrfKey` | The XSRF key. Will be generated automatically if it isn't specified | |
| **Jobservice**                                                              |
| `jobservice.image.repository`                                               | Repository for jobservice image                                                                                                                                                                                                                                                                                                                 | `goharbor/harbor-jobservice`    |
| `jobservice.image.tag`                                                      | Tag for jobservice image                                                                                                                                                                                                                                                                                                                        | `dev`                           |
| `jobservice.replicas`                                                       | The replica count                                                                                                                                                                                                                                                                                                                               | `1`                             |
| `jobservice.maxJobWorkers`                                                  | The max job workers                                                                                                                                                                                                                                                                                                                             | `10`                            |
| `jobservice.jobLogger`                                                      | The logger for jobs: `file`, `database` or `stdout`                                                                                                                                                                                                                                                                                             | `file`                          |
| `jobservice.resources`                                                      | The [resources] to allocate for container                                                                                                                                                                                                                                                                                                       | undefined                       |
| `jobservice.nodeSelector`                                                   | Node labels for pod assignment                                                                                                                                                                                                                                                                                                                  | `{}`                            |
| `jobservice.tolerations`                                                    | Tolerations for pod assignment                                                                                                                                                                                                                                                                                                                  | `[]`                            |
| `jobservice.affinity`                                                       | Node/Pod affinities                                                                                                                                                                                                                                                                                                                             | `{}`                            |
| `jobservice.podAnnotations`                                                 | Annotations to add to the jobservice pod                                                                                                                                                                                                                                                                                                        | `{}`                            |
| `jobservice.secret`                                                         | Secret is used when job service communicates with other components. If a secret key is not specified, Helm will generate one. Must be a string of 16 chars.                                                                                                                                                                                     |                                 |
| **Registry**                                                                |
| `registry.registry.image.repository`                                        | Repository for registry image                                                                                                                                                                                                                                                                                                                   | `goharbor/registry-photon`      |
| `registry.registry.image.tag`                                               | Tag for registry image                                                                                                                                                                                                                                                                                                                          |
| `registry.registry.resources`                                               | The [resources] to allocate for container                                                                                                                                                                                                                                                                                                       | undefined                       |  | `dev` |
| `registry.controller.image.repository`                                      | Repository for registry controller image                                                                                                                                                                                                                                                                                                        | `goharbor/harbor-registryctl`   |
| `registry.controller.image.tag`                                             | Tag for registry controller image                                                                                                                                                                                                                                                                                                               |
| `registry.controller.resources`                                             | The [resources] to allocate for container                                                                                                                                                                                                                                                                                                       | undefined                       |  | `dev` |
| `registry.replicas`                                                         | The replica count                                                                                                                                                                                                                                                                                                                               | `1`                             |
| `registry.nodeSelector`                                                     | Node labels for pod assignment                                                                                                                                                                                                                                                                                                                  | `{}`                            |
| `registry.tolerations`                                                      | Tolerations for pod assignment                                                                                                                                                                                                                                                                                                                  | `[]`                            |
| `registry.affinity`                                                         | Node/Pod affinities                                                                                                                                                                                                                                                                                                                             | `{}`                            |
| `registry.middleware`                                                       | Middleware is used to add support for a CDN between backend storage and `docker pull` recipient.  See [official docs](https://github.com/docker/distribution/blob/master/docs/configuration.md#middleware).
| `registry.podAnnotations`                                                   | Annotations to add to the registry pod                                                                                                                                                                                                                                                                                                          | `{}`                            |
| `registry.secret`                                                           | Secret is used to secure the upload state from client and registry storage backend. See [official docs](https://github.com/docker/distribution/blob/master/docs/configuration.md#http). If a secret key is not specified, Helm will generate one. Must be a string of 16 chars.                                                                                 |                                 |
| **Chartmuseum**                                                             |
| `chartmuseum.enabled`                                                       | Enable chartmusuem to store chart                                                                                                                                                                                                                                                                                                               | `true`                          |
| `chartmuseum.absoluteUrl`                                                   | If true, ChartMuseum will return absolute URLs. The default behavior is to return relative URLs                                                                                                                                                                                                                                                 | `false`                         |
| `chartmuseum.image.repository`                                              | Repository for chartmuseum image                                                                                                                                                                                                                                                                                                                | `goharbor/chartmuseum-photon`   |
| `chartmuseum.image.tag`                                                     | Tag for chartmuseum image                                                                                                                                                                                                                                                                                                                       | `dev`                           |
| `chartmuseum.replicas`                                                      | The replica count                                                                                                                                                                                                                                                                                                                               | `1`                             |
| `chartmuseum.resources`                                                     | The [resources] to allocate for container                                                                                                                                                                                                                                                                                                       | undefined                       |
| `chartmuseum.nodeSelector`                                                  | Node labels for pod assignment                                                                                                                                                                                                                                                                                                                  | `{}`                            |
| `chartmuseum.tolerations`                                                   | Tolerations for pod assignment                                                                                                                                                                                                                                                                                                                  | `[]`                            |
| `chartmuseum.affinity`                                                      | Node/Pod affinities                                                                                                                                                                                                                                                                                                                             | `{}`                            |
| `chartmuseum.podAnnotations`                                                | Annotations to add to the chart museum pod                                                                                                                                                                                                                                                                                                      | `{}`                            |
| **Clair** |
| `clair.enabled` | Enable Clair | `true` |
| `clair.clair.image.repository`  | Repository for clair image | `goharbor/clair-photon` |
| `clair.clair.image.tag` | Tag for clair image | `dev` |
| `clair.clair.resources` | The [resources] to allocate for clair container | |
| `clair.adapter.image.repository`  | Repository for clair adapter image | `goharbor/clair-adapter-photon` |
| `clair.adapter.image.tag` | Tag for clair adapter image | `dev` |
| `clair.adapter.resources` | The [resources] to allocate for clair adapter container | |
| `clair.replicas` | The replica count | `1` |
| `clair.updatersInterval` | The interval of clair updaters, the unit is hour, set to 0 to disable the updaters | `12` |
| `clair.nodeSelector` | Node labels for pod assignment | `{}` |
| `clair.tolerations` | Tolerations for pod assignment | `[]` |
| `clair.affinity` | Node/Pod affinities | `{}` |
| `clair.podAnnotations` | Annotations to add to the clair pod | `{}` |
| **Notary**                                                                  |
| `notary.enabled`                                                            | Enable Notary?                                                                                                                                                                                                                                                                                                                                  | `true`                          |
| `notary.server.image.repository`                                            | Repository for notary server image                                                                                                                                                                                                                                                                                                              | `goharbor/notary-server-photon` |
| `notary.server.image.tag`                                                   | Tag for notary server image                                                                                                                                                                                                                                                                                                                     | `dev`                           |
| `notary.server.replicas`                                                    | The replica count                                                                                                                                                                                                                                                                                                                               |
| `notary.server.resources`                                                   | The [resources] to allocate for container                                                                                                                                                                                                                                                                                                       | undefined                       |  | `1` |
| `notary.signer.image.repository`                                            | Repository for notary signer image                                                                                                                                                                                                                                                                                                              | `goharbor/notary-signer-photon` |
| `notary.signer.image.tag`                                                   | Tag for notary signer image                                                                                                                                                                                                                                                                                                                     | `dev`                           |
| `notary.signer.replicas`                                                    | The replica count                                                                                                                                                                                                                                                                                                                               |
| `notary.signer.resources`                                                   | The [resources] to allocate for container                                                                                                                                                                                                                                                                                                       | undefined                       |  | `1` |
| `notary.nodeSelector`                                                       | Node labels for pod assignment                                                                                                                                                                                                                                                                                                                  | `{}`                            |
| `notary.tolerations`                                                        | Tolerations for pod assignment                                                                                                                                                                                                                                                                                                                  | `[]`                            |
| `notary.affinity`                                                           | Node/Pod affinities                                                                                                                                                                                                                                                                                                                             | `{}`                            |
| `notary.podAnnotations`                                                     | Annotations to add to the notary pod                                                                                                                                                                                                                                                                                                            | `{}`                            |
| `notary.secretName`                                                         | Fill the name of a kubernetes secret if you want to use your own TLS certificate authority, certificate and private key for notary communications. The secret must contain keys named `tls.ca`, `tls.crt` and `tls.key` that contain the CA, certificate and private key. They will be generated if not set.                                    |                                 |
| **Database** |
| `database.type` | If external database is used, set it to `external` | `internal` |
| `database.internal.image.repository` | Repository for database image | `goharbor/harbor-db` |
| `database.internal.image.tag` | Tag for database image | `dev` |
| `database.internal.initContainerImage.repository` | Repository for the init container image | `busybox` |
| `database.internal.initContainerImage.tag` | Tag for the init container image | `latest` |
| `database.internal.password`                                                | The password for database                                                                                                                                                                                                                                                                                                                       | `changeit`                      |
| `database.internal.resources`                                               | The [resources] to allocate for container                                                                                                                                                                                                                                                                                                       | undefined                       |
| `database.internal.nodeSelector`                                            | Node labels for pod assignment                                                                                                                                                                                                                                                                                                                  | `{}`                            |
| `database.internal.tolerations`                                             | Tolerations for pod assignment                                                                                                                                                                                                                                                                                                                  | `[]`                            |
| `database.internal.affinity`                                                | Node/Pod affinities                                                                                                                                                                                                                                                                                                                             | `{}`                            |
| `database.external.host`                                                    | The hostname of external database                                                                                                                                                                                                                                                                                                               | `192.168.0.1`                   |
| `database.external.port`                                                    | The port of external database                                                                                                                                                                                                                                                                                                                   | `5432`                          |
| `database.external.username`                                                | The username of external database                                                                                                                                                                                                                                                                                                               | `user`                          |
| `database.external.password`                                                | The password of external database                                                                                                                                                                                                                                                                                                               | `password`                      |
| `database.external.coreDatabase`                                            | The database used by core service                                                                                                                                                                                                                                                                                                               | `registry`                      |
| `database.external.clairDatabase`                                           | The database used by clair                                                                                                                                                                                                                                                                                                                      | `clair`                         |
| `database.external.notaryServerDatabase`                                    | The database used by Notary server                                                                                                                                                                                                                                                                                                              | `notary_server`                 |
| `database.external.notarySignerDatabase`                                    | The database used by Notary signer                                                                                                                                                                                                                                                                                                              | `notary_signer`                 |
| `database.external.sslmode`                                                 | Connection method of external database (require, verify-full, verify-ca, disable)                                                                                                                                                                                                                                                               | `disable` |
| `database.maxIdleConns` | The maximum number of connections in the idle connection pool. If it <=0, no idle connections are retained. | `50` |
| `database.maxOpenConns` | The maximum number of open connections to the database. If it <= 0, then there is no limit on the number of open connections. | `100` |
| `database.podAnnotations`                                                   | Annotations to add to the database pod                                                                                                                                                                                                                                                                                                          | `{}`                            |
| **Redis** |
| `redis.type` | If external redis is used, set it to `external` | `internal` |
| `redis.internal.image.repository` | Repository for redis image | `goharbor/redis-photon` |
| `redis.internal.image.tag` | Tag for redis image | `dev` |
| `redis.internal.resources` | The [resources] to allocate for container | undefined |
| `redis.internal.nodeSelector` | Node labels for pod assignment | `{}` |
| `redis.internal.tolerations` | Tolerations for pod assignment | `[]` |
| `redis.internal.affinity` | Node/Pod affinities | `{}` |
| `redis.external.addr` | The addr of external Redis: <host_redis>:<port_redis>. When using sentinel, it should be <host_sentinel1>:<port_sentinel1>,<host_sentinel2>:<port_sentinel2>,<host_sentinel3>:<port_sentinel3> | `192.168.0.2:6379` |
| `redis.external.sentinelMasterSet` | The name of the set of Redis instances to monitor | |
| `redis.external.coreDatabaseIndex` | The database index for core | `0` |
| `redis.external.jobserviceDatabaseIndex` | The database index for jobservice | `1` |
| `redis.external.registryDatabaseIndex` | The database index for registry | `2` |
| `redis.external.chartmuseumDatabaseIndex` | The database index for chartmuseum | `3` |
| `redis.external.trivyAdapterIndex` | The database index for trivy adapter | `5` |
| `redis.external.password` | The password of external Redis | |
| `redis.podAnnotations` | Annotations to add to the redis pod | `{}` |
| **Exporter** |
| `exporter.replicas` ｜ The replica count | `1` |
| `exporter.podAnnotations` | Annotations to add to the exporter pod | `{}` |
| `exporter.image.repository` | Repository for redis image | `goharbor/harbor-exporter` |
| `exporter.image.tag` | Tag for exporter image | `dev` |
| `exporter.nodeSelector` |  Node labels for pod assignment | `{}` |
| `exporter.tolerations` | Tolerations for pod assignment | `[]` |
| `exporter.affinity` | Node/Pod affinities | `{}` |
| `exporter.cacheDuration` | the cache duration for infomation that exporter collected from Harbor | `30` |
| `exporter.cacheCleanInterval` | cache clean interval for infomation that exporter collected from Harbor | `14400` |
| **Metrics** |
| `metrics.enabled`| if enable harbor metrics | `false` |
| `metrics.core.path`| the url path for core metrics | `/metrics` |
| `metrics.core.port` | the port for core metrics | `8001` |
| `metrics.registry.path` | the url path for registry metrics | `/metrics` |
| `metrics.registry.port` | the port for registry metrics | `8001` |
| `metrics.exporter.path` | the url path for exporter metrics | `/metrics` |
| `metrics.exporter.port` | the port for exporter metrics | `8001` |
