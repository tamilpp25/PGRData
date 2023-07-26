--=============
--Ui地鼠对象控件
--=============
local XUiMole = XClass(nil, "XUiMole")
--有限状态机字典
--Key: 状态枚举值 XHitMouseConfigs.MoleStatus
--Value: 状态机
local FSM_DIC = {}
local CsGameObject = CS.UnityEngine.GameObject
function XUiMole:Ctor(prefab, index, onHitCb)
    self.Index = index
    self.MolePrefabs = {}
    self.OnHitCb = onHitCb
    XTool.InitUiObjectByUi(self, prefab)
    self:Init()
    if self.MoleHole then
        XUiHelper.RegisterClickEvent(self, self.MoleHole, function() self:OnClick() end)
    end
end

function XUiMole:Init()
    self:SetDefault()
end

function XUiMole:Clear(finishCb)
    if self.Status == XHitMouseConfigs.MoleStatus.Default or
        self.Status == XHitMouseConfigs.MoleStatus.Disappear then
        if finishCb then
            finishCb()
        end
        return
    end
    if self.Mole and self.Mole.GameObject.activeInHierarchy then
        self:ChangeStatus(XHitMouseConfigs.MoleStatus.Disappear)
        self.OnDisappearFinishCb = finishCb
    else
        if finishCb then
            finishCb()
        end
    end
end
--===============
--设置地鼠
--@param moleId:
--===============
function XUiMole:SetMole(moleId)
    if self.CurrentPrefab then self.CurrentPrefab.gameObject:SetActiveEx(false) end
    if moleId and moleId > 0 then
        local moleCfg = XHitMouseConfigs.GetCfgByIdKey(
            XHitMouseConfigs.TableKey.Mole,
            moleId
        )
        self.Type = moleCfg.Type
        self.isNeedHit = moleCfg.Type == 1
        self.Effect = moleCfg.Effect
        self.ShowTimeAffix = moleCfg.ShowTimeAffix
        self.CanBeHit = moleCfg.CanBeHit
        self.Name = moleCfg.Name
        self:LoadMolePrefab(moleCfg.Prefab)
    end
    self.ContainId = moleId
end

function XUiMole:SetDefault()
    self.ContainId = -1
    self:ChangeStatus(XHitMouseConfigs.MoleStatus.Default)
end

function XUiMole:StartStatus()
    if not self.FSM then return end
    self.FSM.OnStart(self)
end

function XUiMole:UpdateStatus()
    if not self.FSM then return end
    self.FSM.OnUpdate(self)
end

function XUiMole:ExitStatus()
    if not self.FSM then return end
    self.FSM.OnExit(self)
end

function XUiMole:ChangeStatus(status)
    if self.Status == status then return end
    self:ExitStatus()
    self:SetStatus(status)
    self:StartStatus()
end

function XUiMole:SetStatus(status)
    self.Status = status or XHitMouseConfigs.MoleStatus.Default
    if FSM_DIC[self.Status] then
        self.FSM = FSM_DIC[self.Status]
        return
    end
    local statusName = XHitMouseConfigs.MoleStatusName[self.Status]
    if not statusName then
        statusName = "Default"
    end
    local fsmName = "XUiMole" .. statusName .. "Status"
    local fsm = require("XUi/XUiHitMouse/MoleStatus/" .. fsmName)
    FSM_DIC[self.Status] = fsm
    self.FSM = FSM_DIC[self.Status]
end
--=============
--检查是否被击中到消失次数
--=============
function XUiMole:CheckHitCount()
    if self.ContainId <= 0 then
        return false
    end
    if not self.CanBeHit then
        local moleCfg = XHitMouseConfigs.GetCfgByIdKey(
            XHitMouseConfigs.TableKey.Mole,
            self.ContainId
        )
        self.CanBeHit = moleCfg.CanBeHit
    end
    return self.FeverHit or self.HitCount >= self.CanBeHit
end

function XUiMole:CheckShowTime(maxShowTime)
    if self.ContainId <= 0 then
        return
    end
    if self.ShowStartFlag == true then
        self.ShowTimeCount = CS.UnityEngine.Time.deltaTime + self.ShowTimeCount
        if self.ShowTimeCount >= (self.ShowTimeAffix * maxShowTime) then
            self.ShowStartFlag = false
            self.ShowTimeEnd = true
        end
    end
end

function XUiMole:Appear(finishCb)
    if self.Mole and self.Mole.Appear then
        self.AnimGaiziEnable:Stop()
        self.AnimGaiziDisable:Stop()
        self.AnimGaiziDisable:Play()
        if not string.IsNilOrEmpty(self.Effect) then
            self[self.Effect].gameObject:SetActiveEx(true)
        end
        self.Mole:Appear(finishCb)
    end
end

function XUiMole:Hit(finishCb)
    if self.Mole and self.Mole.Hit then
        self.Mole:Hit(finishCb)
    end
end

function XUiMole:Disappear(finishCb)
    if self.Mole and self.Mole.Disappear then
        self.AnimGaiziDisable:Stop()
        self.AnimGaiziEnable:Stop()
        self.AnimGaiziEnable:Play()
        if not string.IsNilOrEmpty(self.Effect) then
            self[self.Effect].gameObject:SetActiveEx(false)
        end
        self.Mole:Disappear(finishCb)
    end
end

function XUiMole:Wait()
    if self.Mole and self.Mole.Wait then
        self.Mole:Wait()
    end
end

function XUiMole:Dead()
    self.IsDied = true
end

function XUiMole:OnClick()
    if self.Status == XHitMouseConfigs.MoleStatus.Wait or
        self.Status == XHitMouseConfigs.MoleStatus.Hit then
        --XLog.Debug("Debug：击中坑位" .. self.Index .. "号" .. "的" .. self.Name)
        self.HitCount = self.HitCount + 1
        self.BeHit = true
        if self.OnHitCb then
            self.OnHitCb()
        end
    end
end

function XUiMole:LoadMolePrefab(prefabPath)
    if not self.MolePrefabs[prefabPath] then
        local newRole = XUiHelper.Instantiate(self.Role.gameObject, self.Transform)
        local prefab = newRole:LoadPrefab(prefabPath)
        self.MolePrefabs[prefabPath] = prefab
        self.CurrentPrefab = self.MolePrefabs[prefabPath]
    else
        self.CurrentPrefab = self.MolePrefabs[prefabPath]
    end
    if not self.Mole then
        local XRole = require("XUi/XUiHitMouse/Mole/XUiHitMouseRole")
        self.Mole = XRole.New(self.Role)
    end
    self.Mole:RefreshPrefab(self.CurrentPrefab)
    self.CurrentPrefab.gameObject:SetActiveEx(false)
end

return XUiMole