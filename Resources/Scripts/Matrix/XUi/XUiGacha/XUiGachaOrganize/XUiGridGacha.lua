local XUiGridGacha = XClass(nil, "XUiGridGacha")

function XUiGridGacha:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self:InitComponent()
end

function XUiGridGacha:InitComponent()
    self.Normal.gameObject:SetActiveEx(false)
    self.Disable.gameObject:SetActiveEx(true)

    self.ImgSuo.gameObject:SetActiveEx(true)
    self.GridCondition.gameObject:SetActiveEx(false)
    self.TxtKcbz.gameObject:SetActiveEx(false)

    local text = CS.XTextManager.GetText("GachaOrganizeUnlockTips")
    self.TxtCondition.text = string.gsub(text, "\\n", "\n")
end

function XUiGridGacha:Refresh(organizeId, gachaId)
    self.OrganizeId = organizeId
    self.GachaId = gachaId

    local icon = XGachaConfigs.GetOrganizeGachaIcon(gachaId)
    if icon then
        self.RImgCoverSelect:SetRawImage(icon)
        self.RImgCoverNotSelect:SetRawImage(icon)
    end

    local status = XDataCenter.GachaManager.GetOrganizeGachaStatus(organizeId, gachaId)
    if status == XGachaConfigs.OrganizeGachaStatus.Normal then
        -- 正常，可抽卡
        self.Normal.gameObject:SetActiveEx(true)
        self.Disable.gameObject:SetActiveEx(false)
    else
        -- 不可抽卡
        self.Normal.gameObject:SetActiveEx(false)
        self.Disable.gameObject:SetActiveEx(true)

        if status == XGachaConfigs.OrganizeGachaStatus.Lock then
            -- 锁定
            self.ImgSuo.gameObject:SetActiveEx(true)
            self.GridCondition.gameObject:SetActiveEx(true)
            self.TxtKcbz.gameObject:SetActiveEx(false)

        elseif status == XGachaConfigs.OrganizeGachaStatus.SoldOut then
            -- 售罄
            self.ImgSuo.gameObject:SetActiveEx(false)
            self.GridCondition.gameObject:SetActiveEx(false)
            self.TxtKcbz.gameObject:SetActiveEx(true)
        else
            XLog.Error(string.format("XUiGridGacha:Refresh函数错误，%s不属于XGachaConfigs.OrganizeGachaStatuso类型",
                    tostring(status)))
            return
        end
    end
end

function XUiGridGacha:AfterDrawRefresh()
    self:Refresh(self.OrganizeId, self.GachaId)
end

return XUiGridGacha