local CsXTextManager = CS.XTextManager

local XUiReformAwarenessGrid = XClass(nil, "XUiReformAwarenessGrid")

function XUiReformAwarenessGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)    
end

function XUiReformAwarenessGrid:SetData(data)
    -- 品质
    self.ImgQuality:SetSprite(data:GetQualityIcon())
    -- 图标
    self.RImgIcon:SetRawImage(data:GetIcon())
    -- 等级
    self.TxtLevel.text = data:GetLevel()
    -- 位置
    self.TxtSite.text = "0" .. data:GetSite()
    -- 共鸣
    local ResonanceInfos = data:GetResonanceInfos()
    local obj = nil
    for i = 1, XEquipConfig.MAX_RESONANCE_SKILL_COUNT do
        obj = self["ImgResonance" .. i]
        if obj then
            if ResonanceInfos and ResonanceInfos[i] then
                obj.gameObject:SetActiveEx(data:CheckPosIsAwaken(i))
            else
                obj.gameObject:SetActiveEx(false)
            end
        end
    end
    -- 突破
    local breakthrough = data:GetBreakthrough()
    if breakthrough ~= 0 then
        self.ImgBreakthrough.gameObject:SetActiveEx(true)
        local breakthroughIcon = XEquipConfig.GetEquipBreakThroughSmallIcon(breakthrough)
        self.ImgBreakthrough:SetSprite(breakthroughIcon)
    else
        self.ImgBreakthrough.gameObject:SetActiveEx(false)
    end
end

--######################## XUiReformWeaponGrid ########################
local XUiReformWeaponGrid = XClass(nil, "XUiReformWeaponGrid")

function XUiReformWeaponGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self) 
end

function XUiReformWeaponGrid:SetData(data)
    -- 头像
    self.RImgIcon:SetRawImage(data:GetIcon())
    -- 品质
    self.ImgQuality:SetSprite(data:GetQualityIcon())
    -- 等级
    self.TxtLevel.text = data:GetLevel()
    -- 名字
    self.TxtName.text = data:GetName()
    -- 共鸣
    local ResonanceInfos = data:GetResonanceInfos()
    local obj = nil
    for i = 1, XEquipConfig.MAX_RESONANCE_SKILL_COUNT do
        obj = self["ImgResonance" .. i]
        if obj then
            if ResonanceInfos and ResonanceInfos[i] then
                obj:SetSprite(XEquipConfig.GetEquipResoanceIconPath(false))
                obj.gameObject:SetActiveEx(true)
            else
                obj.gameObject:SetActiveEx(false)
            end
        end
    end
    -- 突破
    local breakthrough = data:GetBreakthrough()
    if breakthrough ~= 0 then
        self.ImgBreakthrough.gameObject:SetActiveEx(true)
        local breakthroughIcon = XEquipConfig.GetEquipBreakThroughSmallIcon(breakthrough)
        self.ImgBreakthrough:SetSprite(breakthroughIcon)
    else
        self.ImgBreakthrough.gameObject:SetActiveEx(false)
    end
end

--######################## XUiReformCharacterInfo ########################
local XUiReformCharacterInfo = XLuaUiManager.Register(XLuaUi, "UiReformCharacterInfo")

function XUiReformCharacterInfo:OnAwake()
    self.Source = nil
    self.UiReformWeaponGrid = XUiReformWeaponGrid.New(self.GridWeapon)
    self.UiAwarenessGridDic = {}
    self.UiReformRoleList = nil
    self:RegisterUiEvents()
    -- 特殊处理
    self.BtnLevelUpText.text = CsXTextManager.GetText("ReformCharDetailText")
    self.ImgRedPoint.gameObject:SetActiveEx(false)
end

function XUiReformCharacterInfo:OnStart(uiReformRoleList)
    self.UiReformRoleList = uiReformRoleList
end

function XUiReformCharacterInfo:Open()
    self.GameObject:SetActiveEx(true)
end

function XUiReformCharacterInfo:SetData(source)
    self.Source = source
    local robot = source:GetRobot()
    local characterViewModel = robot:GetCharacterViewModel()
    -- 头像
    self.RImgTypeIcon:SetRawImage(characterViewModel:GetProfessionIcon())
    -- 名字
    self.TxtName.text = characterViewModel:GetName()    
    -- 战力参数
    self.TxtLv.text = math.floor(characterViewModel:GetAbility())
    -- 型号
    self.TxtNameOther.text = characterViewModel:GetTradeName()
    -- 元素列表
    local elementList = characterViewModel:GetObtainElements()
    local rImg = nil
    for i = 1, 3 do
        rImg = self["RImgCharElement" .. i]
        if elementList[i] then
            rImg.gameObject:SetActiveEx(true)
            rImg:SetRawImage(XCharacterConfigs.GetCharElement(elementList[i]).Icon)
        else
            rImg.gameObject:SetActiveEx(false)
        end
    end
    -- 装备
    self.UiReformWeaponGrid:SetData(robot:GetWeaponViewModel())
    -- 伙伴
    local partner = robot:GetPartner()
    if partner and next(partner) ~= nil then
        self.PartnerIcon:SetRawImage(partner:GetIcon())
    end
    -- 意识
    local awarenessViewModelDic = robot:GetAwarenessViewModelDic()
    local awarenessViewModel = nil
    for _, equipSite in pairs(XEquipConfig.EquipSite.Awareness) do
        self.UiAwarenessGridDic[equipSite] = self.UiAwarenessGridDic[equipSite] 
            or XUiReformAwarenessGrid.New(CS.UnityEngine.Object.Instantiate(self.GridAwareness))
        self.UiAwarenessGridDic[equipSite].Transform:SetParent(self["PanelAwareness" .. equipSite], false)
        awarenessViewModel = awarenessViewModelDic[equipSite]
        if not awarenessViewModel then
            self.UiAwarenessGridDic[equipSite].GameObject:SetActiveEx(false)
            self["PanelNoAwareness" .. equipSite].gameObject:SetActiveEx(true)
        else
            self.UiAwarenessGridDic[equipSite].GameObject:SetActiveEx(true)
            self["BtnAwarenessReplace" .. equipSite].transform:SetAsLastSibling()
            self["PanelNoAwareness" .. equipSite].gameObject:SetActiveEx(false)
            self.UiAwarenessGridDic[equipSite]:SetData(awarenessViewModel)
        end
    end
end

function XUiReformCharacterInfo:Close()
    self.GameObject:SetActiveEx(false)
end

--######################## 私有方法 ########################

function XUiReformCharacterInfo:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnCareerTips, self.OnBtnCareerTipsClicked)
    self:RegisterClickEvent(self.BtnWeaponReplace, self.OnBtnWeaponReplaceClicked)
    self:RegisterClickEvent(self.BtnAwarenessReplace6, self.OnBtnAwarenessReplace6Click)
    self:RegisterClickEvent(self.BtnAwarenessReplace5, self.OnBtnAwarenessReplace5Click)
    self:RegisterClickEvent(self.BtnAwarenessReplace4, self.OnBtnAwarenessReplace4Click)
    self:RegisterClickEvent(self.BtnAwarenessReplace3, self.OnBtnAwarenessReplace3Click)
    self:RegisterClickEvent(self.BtnAwarenessReplace2, self.OnBtnAwarenessReplace2Click)
    self:RegisterClickEvent(self.BtnAwarenessReplace1, self.OnBtnAwarenessReplace1Click)
    self:RegisterClickEvent(self.BtnLevelUp, self.OnBtnLevelUpClicked)
    self.BtnElementDetail.CallBack = function() self:OnBtnElementDetailClicked() end
    self.BtnCarryPartner.CallBack = function() self:OnCarryPartnerClicked() end
end

function XUiReformCharacterInfo:OnBtnLevelUpClicked()
    self.UiReformRoleList:OpenUiReformCharacterDetailInfo()
end

function XUiReformCharacterInfo:OnBtnCareerTipsClicked()
    XLuaUiManager.Open("UiCharacterCarerrTips",XRobotManager.GetCharacterId(self.Source:GetRobotId()))
end

function XUiReformCharacterInfo:OnBtnElementDetailClicked()
    XLuaUiManager.Open("UiCharacterElementDetail", XRobotManager.GetCharacterId(self.Source:GetRobotId()))
end

function XUiReformCharacterInfo:OnBtnWeaponReplaceClicked()
    local robot = self.Source:GetRobot()
    XLuaUiManager.Open("UiEquipDetailOther", robot:GetWeaponViewModel():GetEquip(), robot:GetCharacterViewModel():GetCharacter())
end

function XUiReformCharacterInfo:OnCarryPartnerClicked()
    local robot = self.Source:GetRobot()
    local partner = robot:GetPartner()
    if partner and next(partner) ~= nil then
        XLuaUiManager.Open("UiPartnerPropertyOther", partner)
    end
end

function XUiReformCharacterInfo:OnAwarenessClick(index)
    local robot = self.Source:GetRobot()
    local awarenessViewModelDic = robot:GetAwarenessViewModelDic()
    if awarenessViewModelDic[index] == nil then
        return
    end
    XLuaUiManager.Open("UiEquipDetailOther", awarenessViewModelDic[index]:GetEquip(), robot:GetCharacterViewModel():GetCharacter())
end

function XUiReformCharacterInfo:OnBtnAwarenessReplace6Click()
    self:OnAwarenessClick(6)
end

function XUiReformCharacterInfo:OnBtnAwarenessReplace5Click()
    self:OnAwarenessClick(5)
end

function XUiReformCharacterInfo:OnBtnAwarenessReplace4Click()
    self:OnAwarenessClick(4)
end

function XUiReformCharacterInfo:OnBtnAwarenessReplace3Click()
    self:OnAwarenessClick(3)
end

function XUiReformCharacterInfo:OnBtnAwarenessReplace2Click()
    self:OnAwarenessClick(2)
end

function XUiReformCharacterInfo:OnBtnAwarenessReplace1Click()
    self:OnAwarenessClick(1)
end

return XUiReformCharacterInfo