local XRedPointDlcCasualActivity = {}

function XRedPointDlcCasualActivity.Check()
    return XMVCA.XDlcCasual:CheckAllTasksAchieved()
end

return XRedPointDlcCasualActivity