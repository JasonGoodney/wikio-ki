//
//  AboutViewController.swift
//  picture
//
//  Created by Jason Goodney on 1/27/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

enum AboutType: String {
    case privacyPolicy = "Privacy Policy"
    case termsOfService = "Terms of Service"
    case openSource = "Open Source Libraries"
}

class AboutViewController: UIViewController, UITableViewDataSource {

    var type: AboutType = .privacyPolicy
    
    private let textLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        
        return scrollView
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        return tableView
    }()
    
    private let contentView = UIView()
    
    private lazy var titleLabel = NavigationTitleLabel(title: type.rawValue)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        view.addSubview(tableView)
        
        tableView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor)
        
        navigationItem.titleView = titleLabel
        
        tableView.tableFooterView = UIView()
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.numberOfLines = 0
        switch type {
        case .privacyPolicy:
            let data = Data(About.privacyPolicyHTML.utf8)
            if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
                cell.textLabel?.attributedText = attributedString
            }
        case .termsOfService:
            let data = Data(About.termsHTML.utf8)
            if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
                cell.textLabel?.attributedText = attributedString
            }
        default:
            cell.textLabel?.text = "None"
        }
        return cell
    }
}

struct About {
    static let privacyPolicy = """
    Privacy Policy
    Jason Goodney built the Wikio Ki app as a Free app. This SERVICE is provided by Jason Goodney at no cost and is intended for use as is.

    This page is used to inform visitors regarding my policies with the collection, use, and disclosure of Personal Information if anyone decided to use my Service.

    If you choose to use my Service, then you agree to the collection and use of information in relation to this policy. The Personal Information that I collect is used for providing and improving the Service. I will not use or share your information with anyone except as described in this Privacy Policy.

    The terms used in this Privacy Policy have the same meanings as in our Terms and Conditions, which is accessible at Wikio Ki unless otherwise defined in this Privacy Policy.

    Information Collection and Use

    For a better experience, while using our Service, I may require you to provide us with certain personally identifiable information. The information that I request will be retained on your device and is not collected by me in any way.

    The app does use third party services that may collect information used to identify you.

    Link to privacy policy of third party service providers used by the app

    AdMob
    Firebase Analytics
    Log Data

    I want to inform you that whenever you use my Service, in a case of an error in the app I collect data and information (through third party products) on your phone called Log Data. This Log Data may include information such as your device Internet Protocol (“IP”) address, device name, operating system version, the configuration of the app when utilizing my Service, the time and date of your use of the Service, and other statistics.

    Cookies

    Cookies are files with a small amount of data that are commonly used as anonymous unique identifiers. These are sent to your browser from the websites that you visit and are stored on your device's internal memory.

    This Service does not use these “cookies” explicitly. However, the app may use third party code and libraries that use “cookies” to collect information and improve their services. You have the option to either accept or refuse these cookies and know when a cookie is being sent to your device. If you choose to refuse our cookies, you may not be able to use some portions of this Service.

    Service Providers

    I may employ third-party companies and individuals due to the following reasons:

    To facilitate our Service;
    To provide the Service on our behalf;
    To perform Service-related services; or
    To assist us in analyzing how our Service is used.
    I want to inform users of this Service that these third parties have access to your Personal Information. The reason is t   o perform the tasks assigned to them on our behalf. However, they are obligated not to disclose or use the information for an   y other purpose.

    Security

    I value your trust in providing us your Personal Information, thus we are striving to use commercially acceptable means of protecting it. But remember that no method of transmission over the internet, or method of electronic storage is 100% secure and reliable, and I cannot guarantee its absolute security.

    Links to Other Sites

    This Service may contain links to other sites. If you click on a third-party link, you will be directed to that site. Note that these external sites are not operated by me. Therefore, I strongly advise you to review the Privacy Policy of these websites. I have no control over and assume no responsibility for the content, privacy policies, or practices of any third-party sites or services.

    Children’s Privacy

    These Services do not address anyone under the age of 13. I do not knowingly collect personally identifiable information from children under 13. In the case I discover that a child under 13 has provided me with personal information, I immediately delete this from our servers. If you are a parent or guardian and you are aware that your child has provided us with personal information, please contact me so that I will be able to do necessary actions.

    Changes to This Privacy Policy

    I may update our Privacy Policy from time to time. Thus, you are advised to review this page periodically for any changes. I will notify you of any changes by posting the new Privacy Policy on this page. These changes are effective immediately after they are posted on this page.

    Contact Us

    If you have any questions or suggestions about my Privacy Policy, do not hesitate to contact me.

    This privacy policy page was created at privacypolicytemplate.net and modified/generated by App Privacy Policy Generator
    """
    
    static let privacyPolicyHTML = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset='utf-8'>
        <meta name='viewport' content='width=device-width'>
        <title>Privacy Policy</title>
        <style> body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; padding:1em; } </style>
        </head>
        <body>
        <h2>Privacy Policy</h2> <p> Jason Goodney built the Wikio Ki app as a Free app. This SERVICE is provided by
                    Jason Goodney at no cost and is intended for use as is.
                  </p> <p>This page is used to inform visitors regarding my policies with the collection, use, and disclosure
                    of Personal Information if anyone decided to use my Service.
                  </p> <p>If you choose to use my Service, then you agree to the collection and use of information in
                    relation to this policy. The Personal Information that I collect is used for providing and improving
                    the Service. I will not use or share your information with anyone except as described
                    in this Privacy Policy.
                  </p> <p>The terms used in this Privacy Policy have the same meanings as in our Terms and Conditions, which is
                    accessible at Wikio Ki unless otherwise defined in this Privacy Policy.
                  </p> <p><strong>Information Collection and Use</strong></p> <p>For a better experience, while using our Service, I may require you to provide us with certain
                    personally identifiable information. The information that I request will be retained on your device and is not collected by me in any way.
                  </p> <p>The app does use third party services that may collect information used to identify you.</p> <div><p>Link to privacy policy of third party service providers used by the app</p> <ul><!----><li><a href="https://support.google.com/admob/answer/6128543?hl=en" target="_blank">AdMob</a></li><li><a href="https://firebase.google.com/policies/analytics" target="_blank">Firebase Analytics</a></li><!----><!----><!----><!----><!----></ul></div> <p><strong>Log Data</strong></p> <p> I want to inform you that whenever you use my Service, in a case of
                    an error in the app I collect data and information (through third party products) on your phone
                    called Log Data. This Log Data may include information such as your device Internet Protocol (“IP”) address,
                    device name, operating system version, the configuration of the app when utilizing my Service,
                    the time and date of your use of the Service, and other statistics.
                  </p> <p><strong>Cookies</strong></p> <p>Cookies are files with a small amount of data that are commonly used as anonymous unique identifiers.
                    These are sent to your browser from the websites that you visit and are stored on your device's internal
                    memory.
                  </p> <p>This Service does not use these “cookies” explicitly. However, the app may use third party code and
                    libraries that use “cookies” to collect information and improve their services. You have the option to
                    either accept or refuse these cookies and know when a cookie is being sent to your device. If you choose
                    to refuse our cookies, you may not be able to use some portions of this Service.
                  </p> <p><strong>Service Providers</strong></p> <p> I may employ third-party companies and individuals due to the following reasons:</p> <ul><li>To facilitate our Service;</li> <li>To provide the Service on our behalf;</li> <li>To perform Service-related services; or</li> <li>To assist us in analyzing how our Service is used.</li></ul> <p> I want to inform users of this Service that these third parties have access to
                    your Personal Information. The reason is to perform the tasks assigned to them on our behalf. However,
                    they are obligated not to disclose or use the information for any other purpose.
                  </p> <p><strong>Security</strong></p> <p> I value your trust in providing us your Personal Information, thus we are striving
                    to use commercially acceptable means of protecting it. But remember that no method of transmission over
                    the internet, or method of electronic storage is 100% secure and reliable, and I cannot guarantee
                    its absolute security.
                  </p> <p><strong>Links to Other Sites</strong></p> <p>This Service may contain links to other sites. If you click on a third-party link, you will be directed
                    to that site. Note that these external sites are not operated by me. Therefore, I strongly
                    advise you to review the Privacy Policy of these websites. I have no control over
                    and assume no responsibility for the content, privacy policies, or practices of any third-party sites
                    or services.
                  </p> <p><strong>Children’s Privacy</strong></p> <p>These Services do not address anyone under the age of 13. I do not knowingly collect
                    personally identifiable information from children under 13. In the case I discover that a child
                    under 13 has provided me with personal information, I immediately delete this from
                    our servers. If you are a parent or guardian and you are aware that your child has provided us with personal
                    information, please contact me so that I will be able to do necessary actions.
                  </p> <p><strong>Changes to This Privacy Policy</strong></p> <p> I may update our Privacy Policy from time to time. Thus, you are advised to review
                    this page periodically for any changes. I will notify you of any changes by posting
                    the new Privacy Policy on this page. These changes are effective immediately after they are posted on
                    this page.
                  </p> <p><strong>Contact Us</strong></p> <p>If you have any questions or suggestions about my Privacy Policy, do not hesitate to contact
                    me.
                  </p> <p>This privacy policy page was created at <a href="https://privacypolicytemplate.net" target="_blank">privacypolicytemplate.net</a>
                    and modified/generated by <a href="https://app-privacy-policy-generator.firebaseapp.com/" target="_blank">App
                      Privacy Policy Generator</a></p>
        </body>
        </html>
      
    """
    
    static let termsHTML = """
        <!DOCTYPE html>
        <html>
        <head>
      <meta charset='utf-8'>
      <meta name='viewport' content='width=device-width'>
      <title>Terms &amp; Conditions</title>
      <style> body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; padding:1em; } </style>
        </head>
        <body>
        <h2>Terms &amp; Conditions</h2> <p>By downloading or using the app, these terms will automatically apply to you – you should make sure
                    therefore that you read them carefully before using the app. You’re not allowed to copy, or modify the
                    app, any part of the app, or our trademarks in any way. You’re not allowed to attempt to extract the
                    source code of the app, and you also shouldn’t try to translate the app into other languages, or make
                    derivative versions. The app itself, and all the trade marks, copyright, database rights and other intellectual
                    property rights related to it, still belong to [Developer/Company name].</p> <p>[Developer/Company name] is committed to ensuring that the app is as useful and efficient as possible. For
                    that reason, we reserve the right to make changes to the app or to charge for its services, at any time
                    and for any reason. We will never charge you for the app or its services without making it very clear
                    to you exactly what you’re paying for.</p> <p>The [App Name] app stores and processes personal data that you have provided to us, in order to provide
                    [my/our] Service. It’s your responsibility to keep your phone and access to the app secure. We therefore
                    recommend that you do not jailbreak or root your phone, which is the process of removing software restrictions
                    and limitations imposed by the official operating system of your device. It could make your phone vulnerable
                    to malware/viruses/malicious programs, compromise your phone’s security features and it could mean that
                    the [App Name] app won’t work properly or at all. </p> <p>You should be aware that there are certain things that [Developer/Company name] will not take responsibility
                    for. Certain functions of the app will require the app to have an active internet connection. The connection
                    can be Wi-Fi, or provided by your mobile network provider, but [Developer/Company name] cannot take responsibility
                    for the app not working at full functionality if you don’t have access to Wi-Fi, and you don’t have any
                    of your data allowance left.
                    </p><p></p><p>If you’re using the app outside of an area with Wi-Fi, you should remember that your terms of the
                        agreement with your mobile network provider will still apply. As a result, you may be charged by
                        your mobile provider for the cost of data for the duration of the connection while accessing the
                        app, or other third party charges. In using the app, you’re accepting responsibility for any such
                        charges, including roaming data charges if you use the app outside of your home territory (i.e. region
                        or country) without turning off data roaming. If you are not the bill payer for the device on which
                        you’re using the app, please be aware that we assume that you have received permission from the bill
                        payer for using the app.</p> <p>Along the same lines, [Developer/Company name] cannot always take responsibility for the way you use
                        the app i.e. You need to make sure that your device stays charged – if it runs out of battery and
                        you can’t turn it on to avail the Service, [Developer/Company name] cannot accept responsibility.</p> <p>With respect to [Developer/Company name]’s responsibility for your use of the app, when you’re using
                        the app, it’s important to bear in mind that although we endeavour to ensure that it is updated and
                        correct at all times, we do rely on third parties to provide information to us so that we can make
                        it available to you. [Developer/Company name] accepts no liability for any loss, direct or indirect,
                        you experience as a result of relying wholly on this functionality of the app.</p> <p>At some point, we may wish to update the app. The app is currently available on  – the
                        requirements for system(and for any additional systems we decide to extend the availability
                        of the app to) may change, and you’ll need to download the updates if you want to keep using the
                        app. [Developer/Company name] does not promise that it will always update the app so that it is relevant
                        to you and/or works with the  version that you have installed on your device. However,
                        you promise to always accept updates to the application when offered to you, We may also wish to
                        stop providing the app, and may terminate use of it at any time without giving notice of termination
                        to you. Unless we tell you otherwise, upon any termination, (a) the rights and licenses granted to
                        you in these terms will end; (b) you must stop using the app, and (if needed) delete it from your
                        device.
                      </p> <p><strong>Changes to This Terms and Conditions</strong></p> <p> [I/We] may update our Terms and Conditions from time to time. Thus, you are advised
                        to review this page periodically for any changes. [I/We] will notify you of any
                        changes by posting the new Terms and Conditions on this page. These changes are effective immediately
                        after they are posted on this page.
                      </p> <p><strong>Contact Us</strong></p> <p>If you have any questions or suggestions about [my/our] Terms and Conditions, do not hesitate
                        to contact [me/us].
                      </p> <p>This Terms and Conditions page was generated by <a href="https://app-privacy-policy-generator.firebaseapp.com/" target="_blank">App Privacy Policy Generator</a></p>
        </body>
        </html>
      
    """
}