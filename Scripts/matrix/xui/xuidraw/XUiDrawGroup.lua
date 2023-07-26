local XUiDrawGroup = XLuaUiManager.Register(XLuaUi, "UiDrawGroup")
local XUiGridBanner = require("XUi/XUiDraw/XUiGridDrawGroupBanner")

function XUiDrawGroup:OnAwake()

end

function XUiDrawGroup:OnStart()
    self:InitAutoScript()

    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:InitBanners()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiDrawGroup:InitAutoScript()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiDrawGroup:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiDrawGroup:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then
        return
    end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiGridDrawGroupBanner:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiDrawGroup:AutoAddListener()
    self.AutoCreateListeners = {}
    --self:RegisterListener(self.SViewBanners, "onValueChanged", self.OnSViewBannersValueChanged)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end
-- auto
function XUiDrawGroup:OnBtnBackClick()
    self:Close()
end

function XUiDrawGroup:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiDrawGroup:InitBanners()
    local infoList = XDataCenter.DrawManager.GetDrawGroupInfos()
    local gridTab = {}
    local availableList = {}

    local count = 0

    local setParent = function()
        count = count + 1
        if count < #availableList then
            return
        end
        for _, info in pairs(infoList) do
            if gridTab[info.Id] then
                gridTab[info.Id].Transform:SetParent(self.PanelContentTabBtns, false)
            end
        end
        --XUiHelper.PlayAnimation(self, "DrawGroupBegin")
    end

    local createBanners = function()
        count = 0
        for _, info in pairs(availableList) do
            local result = CS.XAssetManager.InstantiateUiComponent(info.Banner, self.Name, CS.XResourceRefType.Ui)
            CS.XTool.WaitCoroutine(result, function()
                if result.Error then
                    XLog.Error("XUiDrawGroup InitBanners 函数错误, instantiate生成组件失败, 要挂载的游戏物体是: " .. info.Banner)
                    return
                end

                local banner = result.Asset
                if not banner then
                    XLog.Error("XUiDrawGroup InitBanners 函数错误, 要挂载的游戏物体为空 : " .. info.Banner)
                    return
                end
                gridTab[info.Id] = XUiGridBanner.New(banner, info)
                setParent()
            end)
        end
    end

    local init = function()
        local now = XTime.GetServerNowTimestamp()
        for _, info in pairs(infoList) do
            XDataCenter.DrawManager.GetDrawInfoList(info.Id, function()
                local drawInfoList = XDataCenter.DrawManager.GetDrawInfoListByGroupId(info.Id)
                if #drawInfoList > 0 then
                    local isDefaultTime = info.StartTime <= 0 and info.EndTime <= 0
                    if isDefaultTime or now >= info.StartTime and now <= info.EndTime then
                        table.insert(availableList, info)
                    end
                end
                count = count + 1
                if count >= #infoList then
                    createBanners()
                end
            end)
        end
    end

    if #infoList > 0 then
        init()
    else
        XDataCenter.DrawManager.GetDrawGroupList(function()
            infoList = XDataCenter.DrawManager.GetDrawGroupInfos()
            init()
        end)
    end
end