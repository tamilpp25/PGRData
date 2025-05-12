local XUiPanelTheatre4OutpostCommon = require("XUi/XUiTheatre4/Game/Outpost/XUiPanelTheatre4OutpostCommon")
local XUiPanelTheatre4OutpostBoss = require("XUi/XUiTheatre4/Game/Outpost/XUiPanelTheatre4OutpostBoss")
-- 格子详情弹框
---@class XUiTheatre4Outpost : XLuaUi
---@field private _Control XTheatre4Control
local XUiTheatre4Outpost = XLuaUiManager.Register(XLuaUi, "UiTheatre4Outpost")

function XUiTheatre4Outpost:OnAwake()
    self:RegisterUiEvents()
end

---@param gridData XTheatre4Grid
---@param callback function 回调
---@param cancelCallback function 取消回调
function XUiTheatre4Outpost:OnStart(mapId, gridData, callback, cancelCallback)
    self.PanelGoldChange.gameObject:SetActiveEx(false)
    self.PanelRole.gameObject:SetActiveEx(false)
    self.PanelCommon.gameObject:SetActiveEx(false)
    self.PanelBoss.gameObject:SetActiveEx(false)

    self.MapId = mapId
    self.GridData = gridData
    self.Callback = callback
    self.CancelCallback = cancelCallback
end

function XUiTheatre4Outpost:OnEnable()
    self:RefreshGold()
    self:RefreshCharacterInfo()
    self:RefreshDetail()
    self:RefreshDisableCountDown()
    self:RefreshRedBuyDead()
end

function XUiTheatre4Outpost:OnDestroy()
    self.GridData = nil
    if self.CancelCallback then
        self.CancelCallback()
    end
end

-- 刷新金币
function XUiTheatre4Outpost:RefreshGold()
    -- 金币图标
    local icon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Gold)
    if icon then
        self.RImgGold:SetRawImage(icon)
    end
    -- 金币数量
    self.TxtNum.text = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.Gold)
end

-- 获取角色信息
---@return boolean, { RoleIcon:string, RoleName:string, RoleContent:string }
function XUiTheatre4Outpost:GetCharacterInfo()
    return false, nil
    -- if not self.GridData:IsGridTypeEvent() then
    --     return false, nil
    -- end
    -- local roleIcon, roleName, roleContent
    -- local isShowRole = false
    -- if self.GridData:IsGridTypeEvent() then
    --     local eventId = self.GridData:GetGridEventId()
    --     if XTool.IsNumberValid(eventId) then
    --         roleIcon = self._Control:GetEventRoleIcon(eventId)
    --         roleName = self._Control:GetEventRoleName(eventId)
    --         roleContent = self._Control:GetEventRoleContent(eventId)
    --     end
    -- end
    -- if roleIcon and roleName and roleContent then
    --     isShowRole = true
    -- end
    -- return isShowRole, { RoleIcon = roleIcon, RoleName = roleName, RoleContent = roleContent }
end

-- 刷新角色信息
---@deprecated data { RoleIcon, RoleName, RoleContent }
function XUiTheatre4Outpost:RefreshCharacterInfo()
    local isShowRole, data = self:GetCharacterInfo()
    self.PanelRole.gameObject:SetActiveEx(isShowRole)
    if not isShowRole then
        return
    end
    -- 角色图标
    if data.RoleIcon then
        self.RImgRole:SetRawImage(data.RoleIcon)
    end
    -- 角色名称
    self.TxtRoleName.text = data.RoleName
    -- 角色内容
    self.TxtRoleContent.text = data.RoleContent
end

function XUiTheatre4Outpost:RefreshDetail()
    local id = self.GridData:GetGridDisplayId()
    if self:IsShowCommonDetail() then
        self:ShowCommonDetail(id)
    elseif self:IsShowBossDetail() then
        self:ShowBossDetail(id)
    else
        XLog.Error("XUiTheatre4Outpost:RefreshDetail error: invalid type")
    end
end

-- 是否显示通用详情
function XUiTheatre4Outpost:IsShowCommonDetail()
    return self.GridData:IsGridTypeBox()
            or self.GridData:IsGridTypeShop()
            or self.GridData:IsGridTypeEvent()
end

-- 显示通用详情
function XUiTheatre4Outpost:ShowCommonDetail(id)
    if not self.PanelCommonDetail then
        ---@type XUiPanelTheatre4OutpostCommon
        self.PanelCommonDetail = XUiPanelTheatre4OutpostCommon.New(self.PanelCommon, self)
    end
    self.PanelCommonDetail:Open()
    self.PanelCommonDetail:Refresh(id, self.GridData)
end

-- 是否显示Boss详情
function XUiTheatre4Outpost:IsShowBossDetail()
    return self.GridData:IsGridTypeBoss()
            or self.GridData:IsGridTypeMonster()
end

-- 显示Boss详情
function XUiTheatre4Outpost:ShowBossDetail(id)
    if not self.PanelBossDetail then
        ---@type XUiPanelTheatre4OutpostBoss
        self.PanelBossDetail = XUiPanelTheatre4OutpostBoss.New(self.PanelBoss, self)
    end
    self.PanelBossDetail:Open()
    self.PanelBossDetail:Refresh(id, self.GridData)
end

-- 探索格子
function XUiTheatre4Outpost:ExploreGrid()
    if self.GridData:IsGridStateExplored() then
        self:EnterNextStep()
        return
    end
    -- 已经处理过的格子不再处理
    if self.GridData:IsGridStateProcessed() then
        return
    end
    local posX, posY = self.GridData:GetGridPos()
    self._Control:ExploreGridRequest(self.MapId, posX, posY, function()
        self:EnterNextStep()
    end)
end

-- 招安
function XUiTheatre4Outpost:Recruit()
    -- 已经处理过的格子不再处理
    if self.GridData:IsGridStateProcessed() then
        return
    end
    local posX, posY = self.GridData:GetGridPos()
    self._Control:SweepMonsterRequest(self.MapId, posX, posY, function()
        if self.GridData:IsGridStateProcessed() then
            self:EnterNextStep()
        else
            
            -- 扫荡后，如果有强制事件出现，则关闭界面，返回主界面，弹出强制事件
            local mapId, gridId = self._Control.MapSubControl:GetForcePlayEventMapIdAndGridId()
            if XTool.IsNumberValid(mapId) and XTool.IsNumberValid(gridId) then
                self:EnterNextStep()
                return
            end

            self:RefreshGold()
            self:RefreshCharacterInfo()
            self:RefreshDetail()    
        end
    end)
end

function XUiTheatre4Outpost:BuyDieRed()
    -- 已经处理过的格子不再处理
    if self.GridData:IsGridStateProcessed() then
        return
    end
    local posX, posY = self.GridData:GetGridPos()
    self._Control:SweepMonsterRequest(self.MapId, posX, posY, function()
        if self.GridData:IsGridStateProcessed() then
            self:EnterNextStep()
        else
            
            -- 扫荡后，如果有强制时间出现，则关闭界面，返回主界面，弹出强制事件
            local mapId, gridId = self._Control.MapSubControl:GetForcePlayEventMapIdAndGridId()
            if XTool.IsNumberValid(mapId) and XTool.IsNumberValid(gridId) then
                self:EnterNextStep()
                return
            end
            
            self:RefreshGold()
            self:RefreshCharacterInfo()
            self:RefreshDetail()
        end
    end, XEnumConst.Theatre4.SweepType.Red)
end

-- 进入下一步
function XUiTheatre4Outpost:EnterNextStep()
    XLuaUiManager.CloseWithCallback(self.Name, self.Callback)
end

function XUiTheatre4Outpost:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGold, self.OnBtnGoldClick)
end

function XUiTheatre4Outpost:OnBtnCloseClick()
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_RECOVER_CAMERA_POS)
    self:Close()
end

function XUiTheatre4Outpost:OnBtnGoldClick()
    -- 打开金币详情
    XLuaUiManager.Open("UiTheatre4PopupItemDetail", nil, XEnumConst.Theatre4.AssetType.Gold)
end

function XUiTheatre4Outpost:RefreshDisableCountDown()
    local disabledDay = self.GridData:GetDisabledDay()
    if disabledDay and disabledDay > 0 then
        self.TagTime.gameObject:SetActiveEx(true)
        local currentDay = self._Control:GetDays()
        if currentDay <= disabledDay then
            local disableCountDown = disabledDay - currentDay
            if disableCountDown == 0 then
                self.TxtDisableCountDown.text = self._Control:GetClientConfig("DisableCountDownDesc", 2)
            else
                local countDownDesc = self._Control:GetClientConfig("DisableCountDownDesc", 1)
                self.TxtDisableCountDown.text = XUiHelper.FormatText(countDownDesc, disableCountDown)
            end
        end
    else
        self.TagTime.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre4Outpost:RefreshRedBuyDead()
    --新增持有建设度显示
    --若当前怪物支持使用红色建设度进行代理作战，则在点击怪物格子的详情页右上角，银币数量旁边，显示玩家当前持有的建设度
    local button = self.ButtonRedBuyDead
    if not button then
        return
    end

    if self:IsShowBossDetail() then
        if self._Control.EffectSubControl:GetEffectRedBuyDeadAvailable() then
            button.gameObject:SetActiveEx(true)
            local red = XEnumConst.Theatre4.ColorType.Red
            local value = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.ColorCostPoint, red)
            button:SetNameByGroup(0, value)
            return
        end
    end

    -- 不显示红色买死
    button.gameObject:SetActiveEx(false)
end

return XUiTheatre4Outpost
