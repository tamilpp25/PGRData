local XNameplate = XClass(nil, "XNameplate")

function XNameplate:Ctor(data)
    self:UpdateData(data)
end

function XNameplate:UpdateData(data)
    self.Id = data.Id
    self.LastExp = self.Exp or data.Exp
    self.Exp = data.Exp
    self.EndTime = (self.EndTime and self.EndTime > data.EndTime) and self.EndTime or data.EndTime
    self.GetTime = data.GetTime
    self.Config = XMedalConfigs.GetNameplateConfigById(self.Id)
end


function XNameplate:GetNameplateId()
    return self.Id
end

function XNameplate:GetNamepalteEndTime()
    return self.EndTime
end

function XNameplate:GetNamepalteExp()
    return self.Exp
end

function XNameplate:GetNamepalteLastExp()
    return self.LastExp
end

function XNameplate:GetNamepalteGetTime()
    return self.GetTime
end

function XNameplate:GetNamepalteGetTimeToString()
    if self.GetTime ~= 0 then
        local dayFormat = CS.XTextManager.GetText("UnionCnFormatDate")
        return XTime.TimestampToGameDateTimeString(self.GetTime, dayFormat)
    end
    return
end

function XNameplate:GetNamepalteLeftTime()
    return  self.EndTime - XTime.GetServerNowTimestamp()
end

--判断铭牌是否过期
function XNameplate:IsNamepalteExpire()
    if not self:IsNamepalteForever() then
        local nowTime = XTime.GetServerNowTimestamp()
        if nowTime >= self.EndTime then
            return true
        end
    end
    return false
end

--判断铭牌是否是被穿戴的
function XNameplate:IsNameplateDress()
    return not self:IsNamepalteExpire() and XDataCenter.MedalManager.GetNameplateCurId() == self.Id
end

function XNameplate:IsNameplateNew()
    return XDataCenter.MedalManager.CheckHaveNewNameplateById(self.Id) and not self:IsNamepalteExpire()
end

function XNameplate:GetNameplateName()
    return self.Config.Name
end

function XNameplate:GetNameplateQuality()
    return self.Config.NameplateQuality
end

function XNameplate:GetNameplateGroup()
    return self.Config.Group
end

function XNameplate:GetNameplateDescription()
    return self.Config.Description
end

function XNameplate:GetNameplateGetWay()
    return self.Config.NameplateGetWay
end

function XNameplate:GetNameplateHint()
    return self.Config.Hint
end

function XNameplate:GetNameplateUpgradeType()
    return self.Config.NameplateUpgradeType
end

function XNameplate:GetNameplateConvertItemId()
    return self.Config.ConvertItemId
end

function XNameplate:GetNameplateConvertItemCount()
    return self.Config.ConvertItemCount
end

function XNameplate:GetNameplateTitle()
    return self.Config.Title
end

function XNameplate:GetNameplateIconType()
    return self.Config.IconType
end

function XNameplate:GetNameplateIcon()
    return self.Config.Icon
end

function XNameplate:GetNameplateBackBoard()
    return self.Config.BackBoard
end

function XNameplate:GetNameplateOutLineColor()
    return self.Config.OutLineColor
end

function XNameplate:GetNameplateQualityIcon()
    return self.Config.QualityIcon
end

function XNameplate:IsNamepalteForever()
    return self.EndTime == 0
end

function XNameplate:GetNameplateUpgradeExp()
    return self.Config.UpgradeExp
end

return XNameplate
