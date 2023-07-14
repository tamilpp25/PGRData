local CsXTextManager = CS.XTextManager

--######################## XUiReformCharacterLevelPanel ########################
local XUiReformCharacterLevelPanel = XClass(nil, "XUiReformCharacterLevelPanel")

function XUiReformCharacterLevelPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    -- 特殊处理
    self.ExpBar.gameObject:SetActiveEx(false)
    self.BtnLevelUpButton.gameObject:SetActiveEx(false)
    self.ImgMaxLevel.gameObject:SetActiveEx(false)
    self.BtnLiberation.gameObject:SetActiveEx(false)
end

function XUiReformCharacterLevelPanel:SetData(source)
    local robot = source:GetRobot()
    local characterViewModel = robot:GetCharacterViewModel()
    local attributeDic = characterViewModel:GetAttributes(robot:GetEquipViewModels())
    self.TxtAttack.text = FixToInt(attributeDic[XNpcAttribType.AttackNormal])
    self.TxtLife.text = FixToInt(attributeDic[XNpcAttribType.Life])
    self.TxtDefense.text = FixToInt(attributeDic[XNpcAttribType.DefenseNormal])
    self.TxtCrit.text = FixToInt(attributeDic[XNpcAttribType.Crit])
end

--######################## XUiReformCharacterDetailInfo ########################
local XUiReformCharacterDetailInfo = XLuaUiManager.Register(XLuaUi, "UiReformCharacterDetailInfo")

local PANEL_INDEX = {
    Level = 1,
}

function XUiReformCharacterDetailInfo:OnAwake()
    self:RegisterUiEvents()
    self.Source = nil
    self.UiReformRoleList = nil
    -- 子面板信息配置
    self.ChillPanelInfoDic = {
        [PANEL_INDEX.Level] = {
            uiParent = self.PanelCharLevel,
            assetPath = XUiConfigs.GetComponentUrl("UiPanelCharProperty1"),
            proxy = XUiReformCharacterLevelPanel,
            -- 代理设置参数
            proxyArgs = { "Source" }
        },
    }
    -- 按钮组
    self.PanelPropertyButtons:Init({
        [PANEL_INDEX.Level] = self.BtnTabLevel
    }, function(tabIndex) self:OnBtnGroupClicked(tabIndex) end)
    -- 特殊处理
    self.BtnTabGrade.gameObject:SetActiveEx(false)
    self.BtnTabQuality.gameObject:SetActiveEx(false)
    self.BtnTabSkill.gameObject:SetActiveEx(false)
    self.BtnExchange.gameObject:SetActiveEx(false)
    self.BtnTabLevel:SetNameByGroup(0, CsXTextManager.GetText("ReformCharDetailText"))
end

function XUiReformCharacterDetailInfo:OnStart(uiReformRoleList)
    self.UiReformRoleList = uiReformRoleList
end

function XUiReformCharacterDetailInfo:SetData(source)
    self.Source = source
    self.PanelPropertyButtons:SelectIndex(PANEL_INDEX.Level)
end

--######################## 私有方法 ########################

function XUiReformCharacterDetailInfo:RegisterUiEvents()
end

function XUiReformCharacterDetailInfo:OnBtnGroupClicked(index)
    local childPanelData = self.ChillPanelInfoDic[index]
    if childPanelData == nil then return end
    -- 隐藏其他的子面板
    for key, data in pairs(self.ChillPanelInfoDic) do
        data.uiParent.gameObject:SetActiveEx(key == index)
    end
    -- 加载子面板实体
    local instanceGo = childPanelData.instanceGo
    if instanceGo == nil then
        instanceGo = childPanelData.uiParent:LoadPrefab(childPanelData.assetPath)
        childPanelData.instanceGo = instanceGo
    end
    -- 加载子面板代理
    local instanceProxy = childPanelData.instanceProxy
    if instanceProxy == nil then
        instanceProxy = childPanelData.proxy.New(instanceGo)
        childPanelData.instanceProxy = instanceProxy
    end
    -- 设置子面板代理参数
    local proxyArgs = {}
    if childPanelData.proxyArgs then
        for _, argName in ipairs(childPanelData.proxyArgs) do
            if type(argName) == "string" then
                proxyArgs[#proxyArgs + 1] = self[argName]
            else
                proxyArgs[#proxyArgs + 1] = argName
            end
        end
    end
    instanceProxy:SetData(table.unpack(proxyArgs))
end

return XUiReformCharacterDetailInfo