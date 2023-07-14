--兵法蓝图角色列表角色显示控件
local XUiRpgTowerCharaItem = XClass(nil, "XUiRpgTowerCharaItem")
local XUiRpgTowerStarPanel = require("XUi/XUiRpgTower/Common/XUiRpgTowerStarPanel")
--[[
================
构造函数(一般New对象时)
================
]]
function XUiRpgTowerCharaItem:Ctor(gameObject, showType, clickCallBack, useBigHeadIcon)
    self:Init(gameObject, showType, clickCallBack, useBigHeadIcon)
end
--[[
================
初始化函数(动态列表初始化也调用)
================
]]
function XUiRpgTowerCharaItem:Init(gameObject, showType, clickCallBack, useBigHeadIcon)
    XTool.InitUiObjectByUi(self, gameObject)
    self.ShowType = showType or XDataCenter.RpgTowerManager.CharaItemShowType.OnlyIconAndStar
    self.ClickCb = clickCallBack
    if self.BtnCharacter then
        CsXUiHelper.RegisterClickEvent(self.BtnCharacter, function() self:OnClick() end)
    else
        CsXUiHelper.RegisterClickEvent(self.RImgHeadIcon, function() self:OnClick() end)
    end
    self.UseBigIcon = useBigHeadIcon
end
--[[
================
刷新角色数据
@param rCharacter: XRpgTowerCharacter玩法角色对象
================
]]
function XUiRpgTowerCharaItem:RefreshData(rCharacter)
    self.RCharacter = rCharacter
    if self.ShowType == XDataCenter.RpgTowerManager.CharaItemShowType.Normal then
        if self.TxtName then
            self.TxtName.text = self.RCharacter:GetModelName()
        end
    end
    if self.TxtAbility then self.TxtAbility.text = self.RCharacter:GetAbility() end
    if self.UseBigIcon then
        self.RImgHeadIcon:SetRawImage(self.RCharacter:GetBigHeadIcon())
    else
        self.RImgHeadIcon:SetRawImage(self.RCharacter:GetSmallHeadIcon())
    end
    if self.RImgQuality then
        self.RImgQuality:SetRawImage(self.RCharacter:GetCharaQualityIcon())
    end
    if self.TxtTalent then
        self.TxtTalent.gameObject:SetActiveEx(self.RCharacter:GetCharaTalentType() == XDataCenter.RpgTowerManager.TALENT_TYPE.SINGLE)
    end
    if self.TxtRotate then
        self.TxtRotate.gameObject:SetActiveEx(self.RCharacter:GetCharaTalentType() == XDataCenter.RpgTowerManager.TALENT_TYPE.TEAM)
    end
end
--[[
================
点击事件
================
]]
function XUiRpgTowerCharaItem:OnClick()
    if self.ClickCb then self.ClickCb() end
end

return XUiRpgTowerCharaItem