//
//  ContainerViewController.swift
//  DesignerNewsApp
//
//  Created by James Tang on 16/3/15.
//  Copyright (c) 2015 Meng To. All rights reserved.
//

import UIKit

class ContainerViewController: UIPageViewController {

    @IBOutlet weak var loginButton: UIBarButtonItem!
    @IBOutlet weak var navTitleLabel: UILabel!
    @IBOutlet weak var pageImageView: UIImageView!

    private var loginAction : LoginAction?
    private var loginStateChange : LoginStateHandler?

    lazy var _controllers : [StoriesTableViewController] = {
        let topStories = self.storyboard?.instantiateViewControllerWithIdentifier("StoriesTableViewController") as StoriesTableViewController

        let recentStories = self.storyboard?.instantiateViewControllerWithIdentifier("StoriesTableViewController") as StoriesTableViewController

        recentStories.storySection = .Recent

        return [topStories, recentStories]
    }()

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "MenuSegue" {
            let menuViewController = segue.destinationViewController as MenuViewController
            menuViewController.delegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.whiteColor()

        dataSource = self
        delegate = self

        loginButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Avenir Next", size: 18)!], forState: UIControlState.Normal)

        loginStateChange = LoginStateHandler(handler: { [weak self] (state) -> () in
            if state == .LoggedIn {
                self?.loginButton.title = ""
                self?.loginButton.enabled = false
            } else {
                self?.loginButton.title = "Login"
                self?.loginButton.enabled = true
            }
        })

        turnToPage(0)
        
        if !LocalStore.isIntroVisited() {
            performSegueWithIdentifier("IntroSegue", sender: self)
            LocalStore.setIntroAsVisited()
        }
    }

    func configureForDisplayingViewController(controller: StoriesTableViewController) {
        let title = controller.navigationItem.title
        navTitleLabel.text = title
        
        if title == "Top Stories" {
            pageImageView.image = UIImage(named: "pagecontrol-1")
            animateTitle()
        } else {
            pageImageView.image = UIImage(named: "pagecontrol-2")
            animateTitle()
        }
        
        for vc in _controllers {
            // Fix scroll to top when more than one scroll view on screen
            vc.tableView.scrollsToTop = controller === vc
        }
    }
    
    func animateTitle() {
        pageImageView.alpha = 0
        navTitleLabel.alpha = 0
        UIView.animateWithDuration(0.5, animations: {
            self.pageImageView.alpha = 1
            self.navTitleLabel.alpha = 1
        })
    }

    func turnToPage(index: Int) {
        let controller = _controllers[index]

        var direction = UIPageViewControllerNavigationDirection.Forward

        if let currentViewController = viewControllers.first as? UIViewController {
            let currentIndex = (_controllers as NSArray).indexOfObject(currentViewController)

            if currentIndex > index {
                direction = UIPageViewControllerNavigationDirection.Reverse
            }
        }

        configureForDisplayingViewController(controller)
        setViewControllers([controller],
            direction: direction,
            animated: true) { (completion) -> Void in

        }
    }

    func animateMenuButton() {
        if let button = navigationItem.leftBarButtonItem?.customView as? MenuControl {
            button.menuAnimation()
        }
    }

    // MARK: Action
    @IBAction func menuButtonTouched(sender: AnyObject) {
        performSegueWithIdentifier("MenuSegue", sender: sender)
    }

    @IBAction func loginButtonPressed(sender: AnyObject) {
        if LocalStore.accessToken() == nil {
            loginAction = LoginAction(viewController:self, completion: nil)
        } else {
            LogoutAction()
        }
    }

}

extension ContainerViewController : UIPageViewControllerDataSource {

    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {

        let index = (_controllers as NSArray).indexOfObject(viewController)
        
        if index > 0 {
            return _controllers[index - 1]
        }

        return nil
    }

    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {

        let index = (_controllers as NSArray).indexOfObject(viewController)
        
        if index < _controllers.count - 1 {
            return _controllers[index + 1]
        }

        return nil
    }

}

extension ContainerViewController : UIPageViewControllerDelegate {

    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [AnyObject]) {
        configureForDisplayingViewController(pendingViewControllers.first as StoriesTableViewController)
    }

    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
        if !completed {
            configureForDisplayingViewController(previousViewControllers.first as StoriesTableViewController)
        }
    }

}

extension  ContainerViewController : MenuViewControllerDelegate {

    // MARK: MenuViewControllerDelegate
    func menuViewControllerDidSelectTopStories(controller: MenuViewController) {
        turnToPage(0)
    }

    func menuViewControllerDidSelectRecent(controller: MenuViewController) {
        turnToPage(1)
    }

    func menuViewControllerDidSelectCloseMenu(controller: MenuViewController) {
        animateMenuButton()
    }

    func menuViewControllerDidSelectLogin(controller: MenuViewController) {
        animateMenuButton()
    }

    func menuViewControllerDidSelectLogout(controller: MenuViewController) {
        animateMenuButton()
    }

}
