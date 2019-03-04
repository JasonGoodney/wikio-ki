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
    case none
}

class AboutViewController: UIViewController, UITableViewDataSource {

    var type: AboutType = .none
    
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
    
    init(type: AboutType) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        view.addSubview(tableView)
        
        tableView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor)
        
        navigationItem.titleView = titleLabel
        
        tableView.tableFooterView = UIView()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        if type == .openSource {
            return About.libraries.count
        }
        return 1
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
        case .openSource:
            cell.textLabel?.text = About.libraries[indexPath.section].liscense
        default:
            cell.textLabel?.text = "None"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if type == .openSource {
            return About.libraries[section].name
        }
        return nil
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
    
    static let libraries = [
        (name: "SDWebImage", liscense: """
        Copyright (c) 2009-2017 Olivier Poitrey rs@dailymotion.com
         
        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is furnished
        to do so, subject to the following conditions:
         
        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.
         
        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
        THE SOFTWARE.
        """
        ),
    
    
        (name: "JGProgressHub", liscense: """
            The MIT License (MIT)

            Copyright (c) 2014-2018 Jonas Gessner

            Permission is hereby granted, free of charge, to any person obtaining a copy of
            this software and associated documentation files (the "Software"), to deal in
            the Software without restriction, including without limitation the rights to
            use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
            the Software, and to permit persons to whom the Software is furnished to do so,
            subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all
            copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
            IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
            FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
            COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
            IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
            CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
            """
        ),
        
        (name: "SwiftyCam", liscense: """
            Copyright (c) 2016, Andrew Walz.

            Redistribution and use in source and binary forms, with or without modification,
            are permitted provided that the following conditions are met:

            1. Redistributions of source code must retain the above copyright notice, this
            list of conditions and the following disclaimer.

            2. Redistributions in binary form must reproduce the above copyright notice,
             this list of conditions and the following disclaimer in the documentation
             and/or other materials provided with the distribution.

            THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
            EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
            OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
            SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
            INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
            LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
            OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
            LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
            OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
            ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
            """
        ),
        
        (name: "Digger", liscense: """
            MIT License

            Copyright (c) 2017

            Permission is hereby granted, free of charge, to any person obtaining a copy
            of this software and associated documentation files (the "Software"), to deal
            in the Software without restriction, including without limitation the rights
            to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
            copies of the Software, and to permit persons to whom the Software is
            furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all
            copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
            IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
            FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
            AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
            LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
            OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
            SOFTWARE.
            """
        ),
        
        (name: "NVActivityIndicatorView", liscense: """
            The MIT License (MIT)

            Copyright (c) 2016 Vinh Nguyen

            Permission is hereby granted, free of charge, to any person obtaining a copy
            of this software and associated documentation files (the "Software"), to deal
            in the Software without restriction, including without limitation the rights
            to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
            copies of the Software, and to permit persons to whom the Software is
            furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all
            copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
            IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
            FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
            AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
            LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
            OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
            SOFTWARE.
            """
        ),
        
        (name: "ColorSlider", liscense: """
            The MIT License (MIT)

            Copyright (c) 2016-Present Sachin Patel (http://gizmosachin.com/)

            Permission is hereby granted, free of charge, to any person obtaining a copy
            of this software and associated documentation files (the "Software"), to deal
            in the Software without restriction, including without limitation the rights
            to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
            copies of the Software, and to permit persons to whom the Software is
            furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all
            copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
            IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
            FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
            AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
            LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
            OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
            SOFTWARE.
            """
        ),
        (name: "Firebase", liscense: """
                                     Apache License
                               Version 2.0, January 2004
                            http://www.apache.org/licenses/

        TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

        1. Definitions.

          "License" shall mean the terms and conditions for use, reproduction,
          and distribution as defined by Sections 1 through 9 of this document.

          "Licensor" shall mean the copyright owner or entity authorized by
          the copyright owner that is granting the License.

          "Legal Entity" shall mean the union of the acting entity and all
          other entities that control, are controlled by, or are under common
          control with that entity. For the purposes of this definition,
          "control" means (i) the power, direct or indirect, to cause the
          direction or management of such entity, whether by contract or
          otherwise, or (ii) ownership of fifty percent (50%) or more of the
          outstanding shares, or (iii) beneficial ownership of such entity.

          "You" (or "Your") shall mean an individual or Legal Entity
          exercising permissions granted by this License.

          "Source" form shall mean the preferred form for making modifications,
          including but not limited to software source code, documentation
          source, and configuration files.

          "Object" form shall mean any form resulting from mechanical
          transformation or translation of a Source form, including but
          not limited to compiled object code, generated documentation,
          and conversions to other media types.

          "Work" shall mean the work of authorship, whether in Source or
          Object form, made available under the License, as indicated by a
          copyright notice that is included in or attached to the work
          (an example is provided in the Appendix below).

          "Derivative Works" shall mean any work, whether in Source or Object
          form, that is based on (or derived from) the Work and for which the
          editorial revisions, annotations, elaborations, or other modifications
          represent, as a whole, an original work of authorship. For the purposes
          of this License, Derivative Works shall not include works that remain
          separable from, or merely link (or bind by name) to the interfaces of,
          the Work and Derivative Works thereof.

          "Contribution" shall mean any work of authorship, including
          the original version of the Work and any modifications or additions
          to that Work or Derivative Works thereof, that is intentionally
          submitted to Licensor for inclusion in the Work by the copyright owner
          or by an individual or Legal Entity authorized to submit on behalf of
          the copyright owner. For the purposes of this definition, "submitted"
          means any form of electronic, verbal, or written communication sent
          to the Licensor or its representatives, including but not limited to
          communication on electronic mailing lists, source code control systems,
          and issue tracking systems that are managed by, or on behalf of, the
          Licensor for the purpose of discussing and improving the Work, but
          excluding communication that is conspicuously marked or otherwise
          designated in writing by the copyright owner as "Not a Contribution."

          "Contributor" shall mean Licensor and any individual or Legal Entity
          on behalf of whom a Contribution has been received by Licensor and
          subsequently incorporated within the Work.

        2. Grant of Copyright License. Subject to the terms and conditions of
          this License, each Contributor hereby grants to You a perpetual,
          worldwide, non-exclusive, no-charge, royalty-free, irrevocable
          copyright license to reproduce, prepare Derivative Works of,
          publicly display, publicly perform, sublicense, and distribute the
          Work and such Derivative Works in Source or Object form.

        3. Grant of Patent License. Subject to the terms and conditions of
          this License, each Contributor hereby grants to You a perpetual,
          worldwide, non-exclusive, no-charge, royalty-free, irrevocable
          (except as stated in this section) patent license to make, have made,
          use, offer to sell, sell, import, and otherwise transfer the Work,
          where such license applies only to those patent claims licensable
          by such Contributor that are necessarily infringed by their
          Contribution(s) alone or by combination of their Contribution(s)
          with the Work to which such Contribution(s) was submitted. If You
          institute patent litigation against any entity (including a
          cross-claim or counterclaim in a lawsuit) alleging that the Work
          or a Contribution incorporated within the Work constitutes direct
          or contributory patent infringement, then any patent licenses
          granted to You under this License for that Work shall terminate
          as of the date such litigation is filed.

           4. Redistribution. You may reproduce and distribute copies of the
              Work or Derivative Works thereof in any medium, with or without
              modifications, and in Source or Object form, provided that You
              meet the following conditions:

              (a) You must give any other recipients of the Work or
                  Derivative Works a copy of this License; and

              (b) You must cause any modified files to carry prominent notices
                  stating that You changed the files; and

              (c) You must retain, in the Source form of any Derivative Works
                  that You distribute, all copyright, patent, trademark, and
                  attribution notices from the Source form of the Work,
                  excluding those notices that do not pertain to any part of
                  the Derivative Works; and

              (d) If the Work includes a "NOTICE" text file as part of its
                  distribution, then any Derivative Works that You distribute must
                  include a readable copy of the attribution notices contained
                  within such NOTICE file, excluding those notices that do not
                  pertain to any part of the Derivative Works, in at least one
                  of the following places: within a NOTICE text file distributed
                  as part of the Derivative Works; within the Source form or
                  documentation, if provided along with the Derivative Works; or,
                  within a display generated by the Derivative Works, if and
                  wherever such third-party notices normally appear. The contents
                  of the NOTICE file are for informational purposes only and
                  do not modify the License. You may add Your own attribution
                  notices within Derivative Works that You distribute, alongside
                  or as an addendum to the NOTICE text from the Work, provided
                  that such additional attribution notices cannot be construed
                  as modifying the License.

              You may add Your own copyright statement to Your modifications and
              may provide additional or different license terms and conditions
              for use, reproduction, or distribution of Your modifications, or
              for any such Derivative Works as a whole, provided Your use,
              reproduction, and distribution of the Work otherwise complies with
              the conditions stated in this License.

           5. Submission of Contributions. Unless You explicitly state otherwise,
              any Contribution intentionally submitted for inclusion in the Work
              by You to the Licensor shall be under the terms and conditions of
              this License, without any additional terms or conditions.
              Notwithstanding the above, nothing herein shall supersede or modify
              the terms of any separate license agreement you may have executed
              with Licensor regarding such Contributions.

           6. Trademarks. This License does not grant permission to use the trade
              names, trademarks, service marks, or product names of the Licensor,
              except as required for reasonable and customary use in describing the
              origin of the Work and reproducing the content of the NOTICE file.

           7. Disclaimer of Warranty. Unless required by applicable law or
              agreed to in writing, Licensor provides the Work (and each
              Contributor provides its Contributions) on an "AS IS" BASIS,
              WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
              implied, including, without limitation, any warranties or conditions
              of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
              PARTICULAR PURPOSE. You are solely responsible for determining the
              appropriateness of using or redistributing the Work and assume any
              risks associated with Your exercise of permissions under this License.

           8. Limitation of Liability. In no event and under no legal theory,
              whether in tort (including negligence), contract, or otherwise,
              unless required by applicable law (such as deliberate and grossly
              negligent acts) or agreed to in writing, shall any Contributor be
              liable to You for damages, including any direct, indirect, special,
              incidental, or consequential damages of any character arising as a
              result of this License or out of the use or inability to use the
              Work (including but not limited to damages for loss of goodwill,
              work stoppage, computer failure or malfunction, or any and all
              other commercial damages or losses), even if such Contributor
              has been advised of the possibility of such damages.

           9. Accepting Warranty or Additional Liability. While redistributing
              the Work or Derivative Works thereof, You may choose to offer,
              and charge a fee for, acceptance of support, warranty, indemnity,
              or other liability obligations and/or rights consistent with this
              License. However, in accepting such obligations, You may act only
              on Your own behalf and on Your sole responsibility, not on behalf
              of any other Contributor, and only if You agree to indemnify,
              defend, and hold each Contributor harmless for any liability
              incurred by, or claims asserted against, such Contributor by reason
              of your accepting any such warranty or additional liability.

           END OF TERMS AND CONDITIONS

           APPENDIX: How to apply the Apache License to your work.

              To apply the Apache License to your work, attach the following
              boilerplate notice, with the fields enclosed by brackets "[]"
              replaced with your own identifying information. (Don't include
              the brackets!)  The text should be enclosed in the appropriate
              comment syntax for the file format. We also recommend that a
              file or class name and description of purpose be included on the
              same "printed page" as the copyright notice for easier
              identification within third-party archives.

           Copyright [yyyy] [name of copyright owner]

           Licensed under the Apache License, Version 2.0 (the "License");
           you may not use this file except in compliance with the License.
           You may obtain a copy of the License at

               http://www.apache.org/licenses/LICENSE-2.0

           Unless required by applicable law or agreed to in writing, software
           distributed under the License is distributed on an "AS IS" BASIS,
           WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
           See the License for the specific language governing permissions and
           limitations under the License.

        """
        ),
    ]
}
