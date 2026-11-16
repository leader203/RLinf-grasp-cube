# RLinf-grasp-cube

RLinf 抓取-搬运（grasp & cube transport）仿真采集数据集。

- **仿真环境**：Isaac Sim 4.5 + IsaacLab，PhysX，Kit headless + `--enable_cameras`
- **动作生成**：cuRobo 运动规划（`gripper_prismatic_take_out` / 投放），执行成功才入库
- **数据格式**：LeRobot v2.1（`meta/` + `data/chunk-000/*.parquet` + `videos/`）
- **相机**：`cam_fixed`（全局固定视角）、`cam_tool`（腕部视角），两路 RGB

## 统计

| 项 | 值 |
|---|---|
| episodes | **2483** |
| frames | 1,831,522 |
| 原始体积 | 78.7 GiB |
| 打包分卷 | 45 × 1800 MiB |
| 采集成功率 | ~51% |
| 机器人 | 单臂 + 平行夹爪（prismatic gripper） |

8 个子数据集 `groot_1` … `groot_8`，由 3 台机器 × 各 2 个仿真实例并行采集：

| 子集 | episodes | 机器 |
|---|---|---|
| groot_1 | 457 | node-A |
| groot_2 | 446 | node-A |
| groot_3 | 14 | node-A（早期试跑） |
| groot_4 | 12 | node-A（早期试跑） |
| groot_5 | 421 | node-B |
| groot_6 | 440 | node-B |
| groot_7 | 347 | node-C |
| groot_8 | 346 | node-C |

## 下载

数据以 Release 分卷形式发布，单个文件 1800 MiB（GitHub 单资产上限 2 GiB）。
直接用仓库里的脚本拉取并合并：

```bash
curl -fsSL https://raw.githubusercontent.com/leader203/RLinf-grasp-cube/main/download_dataset.sh -o download_dataset.sh
bash download_dataset.sh
```

脚本会：下载 45 个分卷 + `SHA256SUMS.txt` → 校验 → `cat` 合并 → 解包到 `./dataset/`。

手动方式：

```bash
BASE=https://github.com/leader203/RLinf-grasp-cube/releases/download/dataset-v1
for i in $(seq -w 0 44); do
  curl -L -C - -O "$BASE/RLinf-grasp-cube-dataset.tar.part-0$i"
done
curl -L -O "$BASE/SHA256SUMS.txt"

sha256sum -c SHA256SUMS.txt
cat RLinf-grasp-cube-dataset.tar.part-* > dataset.tar
tar -xf dataset.tar
```

## 目录结构

```
collected/
└── groot_1/                        # 每个子集都是独立的 LeRobot v2.1 数据集
    ├── meta/
    │   ├── info.json               # 特征定义、fps、总帧数
    │   ├── episodes.jsonl
    │   ├── episodes_stats.jsonl
    │   └── tasks.jsonl
    ├── data/chunk-000/
    │   └── episode_000000.parquet  # state / action / timestamp / frame_index ...
    └── videos/chunk-000/
        ├── observation.images.cam_fixed/episode_000000.mp4
        └── observation.images.cam_tool/episode_000000.mp4
```

## 快速加载

```python
from lerobot.common.datasets.lerobot_dataset import LeRobotDataset

ds = LeRobotDataset(repo_id="local/groot_1", root="./dataset/collected/groot_1")
sample = ds[0]
print(sample["observation.state"].shape, sample["action"].shape)
print(sample["observation.images.cam_fixed"].shape)
```

## 许可

仅用于研究与学习。数据由仿真生成，不含真实场景隐私信息。
