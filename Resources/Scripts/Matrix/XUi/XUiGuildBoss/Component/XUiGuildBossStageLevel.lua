--工会boss关卡stage控件
local XUiGuildBossStageLevel = XClass(nil, "XUiGuildBossStageLevel")

local GuildBossStageLevelStatus = 
{
    Normal = 1,--未选择状态
    Lock = 2,--未解锁状态（等级不满足条件）
    UnSelect = 3, --未选中（不能打）
}

function XUiGuildBossStageLevel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.BtnClick.CallBack = function() self:OnBtnClick() end
    self.CurStatus = GuildBossStageLevelStatus.Normal
end

function XUiGuildBossStageLevel:Init(data, parentUi, status)
    self.Data = data
    self.ParentUi = parentUi
    local info = XGuildBossConfig.GetBossStageInfo(self.Data.StageId)
    self.ImgBG:SetRawImage(info.BackGround)
    self.RImgIcon:SetRawImage(info.Icon)
    self.TxtCode.text = info.Code .. self.Data.NameOrder
    self.ImgPoint.fillAmount = self.Data.BuffNeed / 100
    --剩余0说明技能已发动
    if self.Data.BuffNeed == 0 then
    end
    self:UpdateStatus(status)
    self:HideOrder()
    self:SetOrderMark(false)
end

function XUiGuildBossStageLevel:UpdateStatus(status)
    if status == GuildBossStageLevelStatus.Normal then

    elseif status == GuildBossStageLevelStatus.Lock then

    elseif status == GuildBossStageLevelStatus.UnSelect then
        
    end
    self.CurStatus = status
end

--设置是否显示优先标记
function XUiGuildBossStageLevel:SetOrderMark(isOrder)
    self.ImgOrder.gameObject:SetActiveEx(isOrder)
end

--设置战术布局显示数字
function XUiGuildBossStageLevel:SetOrder(num)
    if num == 0 then
        self:HideOrder()
    else
        self.OrderNum.gameObject:SetActiveEx(true)
        self.TxtOrder.text = num
    end
end

--隐藏战术布局
function XUiGuildBossStageLevel:HideOrder()
    self.OrderNum.gameObject:SetActiveEx(false)
end

function XUiGuildBossStageLevel:OnBtnClick()
    self.ParentUi:OnStageLevelClick(self.Data, self)
end

return XUiGuildBossStageLevel