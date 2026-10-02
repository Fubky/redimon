# v0.7 原创美术素材

生成方式：内置 `image_gen`，七次生成。角色、建筑、物件采用真实透明通道，地面与背景为不透明图像。生成图集保留在 `assets/art_v7/`；运行时用 AtlasTexture 区域引用或生成并缓存 96 像素角色帧。没有复制《磁带妖怪》原作素材。

| 素材 | 内容 | 完整提示词 |
|---|---|---|
| `assets/art_v7/creatures.png` | 绒耳猫、旅风犬、团团鼠、苔尾蜥、月纹蛇；各 4 个姿态 | `prompts.json` |
| `assets/art_v7/buildings.png` | 家、商店、繁育花房、仓库 | `prompts.json` |
| `assets/art_v7/props.png` | 16 类树木、岩石、珊瑚、晶体、植被和灯具 | `prompts.json` |
| `assets/art_v7/ground.png` | 五种副本地面与城镇石板路 | `ground-prompt.txt` |
| `assets/art_v7/cliffs.png` | 五种地形的顶部和侧面材质 | `cliff-prompt.txt` |
| `assets/art_v7/title.png` | 与角色设计呼应的远征群岛主视觉 | `title-prompt.txt` |
| `assets/art_v7/details.png` | 池塘、宝箱、下行楼梯、花藤围栏 | `details-prompt.txt` |

角色染色区保留奶油色与暖色饰物。体型、肩高、骨量、肌肉、体长影响尺寸；底色、花纹、白斑、对比、毛质、光泽与瞳色影响像素着色；耳型、脸型、尾型影响局部轮廓，共感影响饰物色，敏捷影响行走节奏。它们仍使用相同 UnitData 和遗传规则。

`world_art.gd` 生成可缓存的 40 像素 TileSet，每种地形包含 16 个地面区域和 16 个邻接墙面区域；海岛使用低对比海水与浅色岸边。`atmosphere.gdshader` 提供缓慢云影、暖色光与探索雾，不接收鼠标，不覆盖 HUD。

当前动画包含每物种 4 个基础姿态，方向采用左右翻转；这不是完整八方向帧动画资源。图集采用手工校准区域，修改源图后需同步边界并运行 `tests/test_art_v7.gd`。
