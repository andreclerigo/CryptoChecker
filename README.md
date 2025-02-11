[![cryptochecker](https://snapcraft.io/cryptochecker/badge.svg)](https://snapcraft.io/cryptochecker)

# CryptoChecker
A simple App to quickly check information about your crypto assets (binance account only)

## Information Displayed
### Percentage
<img align="left" src="https://i.imgur.com/ZRHtcbX.png" height="90"> This represents the Weighted Average of the Percentage change on the last 24hr<br>```percentage = (asset1.priceChange * (asset1.quantity / total)) + (asset2.priceChange * (asset2.quantity / total)) + ...```<br>
### Asset Info
<img align="left" src=https://i.imgur.com/dvHCRjE.png height="250">
<pre>
Crypto Asset Information:
Crypto Logo (Crypto Tag): Crypto amount
                          Crypto value in the selected currency
                          Crypto price change in the last 24hr
                          
Example:  Bitcoin Logo (BTC): 0.000294
                              9.95 EUR 
                              0.482%
                              
I have 0.000294 bitcoins, from that amount it converts for 9.95 EUR
and in the last 24hr it got up 0.428%
</pre>

## Recommendations
- Save your API credentials before putting them in cryptochecker specially **Secret Key** since you won't see it again after creating the API
- Only select **Enable Reading** in the **API Restrictions** section since cryptochecker will only function as a Wallet. You won't need the other functions
- It is recommended to check **Unrestricted (Less Secure)** in the **IP Access Eestrictions** section, if you don't the App will prompt the **Account Page** when it's not being used on the whitelisted IP

## Download it now!
| Linux | Android | Windows |
| ----- | ------- | ------- |
| [![Get it from the Snap Store](https://snapcraft.io/static/images/badges/en/snap-store-black.svg)](https://snapcraft.io/cryptochecker) | [Android APK](https://github.com/andreclerigo/cryptochecker/tree/main/app-release/android) | [Windows Installer](https://github.com/andreclerigo/cryptochecker/tree/main/app-release/windows) |

## Demo
### Android Mobile
<img src="https://i.imgur.com/qDsXtaD.gif" height="600">

### Windows Desktop
<img src="https://i.imgur.com/xJ3GrJP.gif">

### Linux Desktop
<img src="https://i.imgur.com/PUGU140.gif">

## Issues
For any issues or bug contact me at andreclerigo@outlook.com
