-- 兵法蓝图主界面怪物面板：怪物展示控件
local XUiRpgTowerMonsterGrid = XClass(nil, "XUiRpgTowerMonsterGrid")
function XUiRpgTowerMonsterGrid:Ctor(ui, monsterModel)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.MonsterModel = monsterModel
    self.ShowEffect = self.MonsterModel.Transform:Find("ImgEffectHuanren1")
end
--================
--刷新数据
--================
function XUiRpgTowerMonsterGrid:RefreshData(rMonsterId, isBoss)
    if not rMonsterId then self:HideGrid() return end
    self.GameObject:SetActiveEx(true)
    self.MonsterId = rMonsterId
    self:RefreshModel()
    self:RefreshGrid()
    self.MonsterModel:ShowRoleModel()
end
--================
--刷新模型
--================
function XUiRpgTowerMonsterGrid:RefreshModel()
    local monsterNpcDataId = XRpgTowerConfig.GetMonsterNpcDataIdByRMonsterId(self.MonsterId)
    local modelName = XArchiveConfigs.GetMonsterNpcDataById(monsterNpcDataId).ModelId
    self.MonsterModel:UpdateBossModel(modelName, nil, nil, function(model) self:LoadModelCallBack(model) end, true)
    local shadowMeshs = self.MonsterModel.GameObject:GetComponentsInChildren(typeof(CS.XShadowMesh))
    if shadowMeshs then  
        local e = shadowMeshs:GetEnumerator()
        while e:MoveNext() do
            if e.Current then
                e.Current:UpdateMeshShadowHeight(self.MonsterModel.Transform.position.y)
            end
        end
    end
end
--================
--读取模型后回调
--================
function XUiRpgTowerMonsterGrid:LoadModelCallBack(model)
    self:PlaySwitchEffect()
    local rMonsterCfg = XRpgTowerConfig.GetRMonsterCfgById(self.MonsterId)
    local scale = rMonsterCfg.Scale > 0 and rMonsterCfg.Scale or 1
    model.transform.localScale = CS.UnityEngine.Vector3(scale, scale, scale)
    model.transform.localPosition = CS.UnityEngine.Vector3(rMonsterCfg.PositionX, rMonsterCfg.PositionY, rMonsterCfg.PositionZ)
    model.transform.localRotation.eulerAngles = CS.UnityEngine.Vector3(rMonsterCfg.RotationX, rMonsterCfg.RotationY, rMonsterCfg.RotationZ)
end
--================
--刷新UI控件显示
--================
function XUiRpgTowerMonsterGrid:RefreshGrid()
    local rMonsterCfg = XRpgTowerConfig.GetRMonsterCfgById(self.MonsterId)
    self.PanelNameBoss.gameObject:SetActiveEx(rMonsterCfg.IsBoss == 1)
    self.PanelNameNormal.gameObject:SetActiveEx(rMonsterCfg.IsBoss ~= 1)
    self.TxtNormalName01.text = rMonsterCfg.Name
    self.TxtBossName01.text = rMonsterCfg.Name
    self.TxtNormalName02.text = rMonsterCfg.SubName
    self.TxtBossName02.text = rMonsterCfg.SubName
end
--================
--隐藏控件
--================
function XUiRpgTowerMonsterGrid:HideGrid()
    self.GameObject:SetActiveEx(false)
    self.MonsterModel:HideRoleModel()
end
--================
--播放切换特效
--================
function XUiRpgTowerMonsterGrid:PlaySwitchEffect()
    if self.ShowEffect then
        self.ShowEffect.gameObject:SetActiveEx(false)
        self.ShowEffect.gameObject:SetActiveEx(true)
    end
end

return XUiRpgTowerMonsterGrid