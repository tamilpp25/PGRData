--关卡层关卡详细页面
local XUiTierStageDetail = XLuaUiManager.Register(XLuaUi, "UiExpeditionStageDetail")

local TypeStrDic = {}
local FuncName = {
        InitPanel = "InitPanel", --初始化面板
    }

function XUiTierStageDetail:OnStart(eStage, rootUi, onCloseCb)
    self.RootUi = rootUi
    self.EStage = eStage
    self.OnCloseCb = onCloseCb
    self:Init()
end

function XUiTierStageDetail:Init()
    if not next(TypeStrDic) then
        self:InitTypeStrDic()
    end
    self.TypeStr = TypeStrDic[self.EStage:GetStageType()]
    self.Proxy = self:GetProxy()
end

function XUiTierStageDetail:InitTypeStrDic()
    local stageType = XExpeditionConfig.StageType
    for name, typeId in pairs(stageType) do
        TypeStrDic[typeId] = name
    end
end

function XUiTierStageDetail:GetProxy()
    local proxy = require("XUi/XUiExpedition/MainPage/DetailProxy/XUiExpedition".. self.TypeStr .."DetailProxy")
    return proxy.New(self)
end

function XUiTierStageDetail:OnEnable()
    if self.Proxy then self.Proxy:OnEnable() end
end

function XUiTierStageDetail:OnDisable()
    if self.Proxy then self.Proxy:OnDisable() end
    if self.OnCloseCb then
        self.OnCloseCb()
    end
end