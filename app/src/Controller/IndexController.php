<?php

declare(strict_types=1);

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

class IndexController extends AbstractController
{
    #[Route(path: '/', name: 'home')]
    public function indexAction(): Response
    {
        $discSpace = $this->getDiskFree();

        return $this->render('@templates/base.html.twig', [
            'serverTime' => date('Y-m-d H:i:s e T O'),
            'discSpace' => $discSpace,
        ]);
    }

    public function getDiskFree()
    {
        $free_space = disk_free_space('/var');
        if ($free_space !== false) {
            return round($free_space / 1024 / 1024 / 1024, 4);
        } else {
            return 0;
        }
    }
}
