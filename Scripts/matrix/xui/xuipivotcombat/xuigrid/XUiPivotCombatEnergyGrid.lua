local XUiPivotCombatEnergyGrid = XClass(nil, "XUiPivotCombatEnergyGrid")

function XUiPivotCombatEnergyGrid:Ctor(ui)
    
    XTool.InitUiObjectByUi(self, ui)
end

function XUiPivotCombatEnergyGrid:Init(region)
    self.OriRegion = region
end

function XUiPivotCombatEnergyGrid:Refresh(isEntirety, data, level)
    local regionId
    local buffText
    local region = data
    --汇总展示
    if isEntirety then
        self.GridBuffCurrent.gameObject:SetActiveEx(false) --当前等级
        self.GridBuffNormal.gameObject:SetActiveEx(false)
        self.GridBuffLock.gameObject:SetActiveEx(false)
        self.GridBuffEntirety.gameObject:SetActiveEx(true)

        
        local curEnergyLv = region:GetCurSupplyEnergy()
        local maxEnergyLv = region:GetMaxSupplyEnergy()
        
        XTool.InitUiObjectByUi(self, self.GridBuffEntirety)
        
        self.TxtName.text = region:GetRegionName()
        self.TextLevelMax.text = "/"..maxEnergyLv
        self.TextLevelNum.text = curEnergyLv
        buffText = region:GetBuffDesc(curEnergyLv)
        self.ImgIcon:SetRawImage(region:GetIcon())
    else
        self.GridBuffEntirety.gameObject:SetActiveEx(false)
        
        local curEnergyLv = region:GetCurSupplyEnergy()
        -- buff 列表三种状态 1.已经获取；2.当前等级；3.未解锁
        local isGet, isCur, isLock = level < curEnergyLv, level == curEnergyLv, level > curEnergyLv
        self.GridBuffCurrent.gameObject:SetActiveEx(isCur) --当前等级
        self.GridBuffNormal.gameObject:SetActiveEx(isGet)
        self.GridBuffLock.gameObject:SetActiveEx(isLock)
        if isCur then
            XTool.InitUiObjectByUi(self, self.GridBuffCurrent)
        elseif isGet then
            XTool.InitUiObjectByUi(self, self.GridBuffNormal)
        else
            XTool.InitUiObjectByUi(self, self.GridBuffLock)
            self.BtnGo.CallBack = function()
                self:OnClickBtnGo(region)
            end
        end
        if not isLock then
            self.ImgIcon:SetRawImage(region:GetIcon())
        end
        self.TxtName.text = CS.XTextManager.GetText("GuildMemberLevel", level)
        buffText = region:GetBuffDesc(level)
    end
    self.RegionId = regionId
    self.NorTxtBuff.text = buffText
end



function XUiPivotCombatEnergyGrid:OnClickBtnGo(region)
    if not region then
        XLog.Error("XUiPivotCombatEnergyGrid:OnClickBtnGo Error: Not Region Config")
        return
    end
    local isOpen, desc = region:IsOpen()
    if not isOpen then
        XUiManager.TipMsg(desc)
        return
    end
    --可能存在同次级界面跳转同次级界面的情况
    if region:IsSameRegion(self.OriRegion) then
        XUiManager.TipText("PivotCombatSameRegion")
        return
    end
    --避免几个次级区域互跳，UI栈爆炸
    if self.OriRegion then --OriRegion不为空表明是来自次级区域
        XLuaUiManager.Remove("UiPivotCombatSecondary")
    end
    XLuaUiManager.Open("UiPivotCombatSecondary", region)
end

return XUiPivotCombatEnergyGrid