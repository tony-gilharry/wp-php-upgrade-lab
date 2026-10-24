<?php
get_header(); ?>

    <nav class="navbar navbar-expand-lg navbar-dark"> 
        <a class="navbar-brand" href="#"><?php _e( 'This is an agency test. I repeat, this is only a test.', 'travel_agency' ); ?></a> 
        <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarToggler97" aria-controls="navbarTogglerDemo01" aria-expanded="false" aria-label="Toggle navigation"> 
            <span class="navbar-toggler-icon"></span> 
        </button>             
        <div class="collapse navbar-collapse" id="navbarToggler97"> 
            <ul class="navbar-nav mt-2 mt-lg-0 ml-auto "> 
                <li class="nav-item active"> 
                    <?php
                        PG_Smart_Walker_Nav_Menu::$options['template'] = '<span class="sr-only">(current)</span>';
                        wp_nav_menu( array(
                            'menu' => 'Home',
                            'container' => '',
                            'items_wrap' => '<a class="nav-link %2$s" href="#" id="%1$s">%3$s</a>',
                            'walker' => new PG_Smart_Walker_Nav_Menu()
                    ) ); ?> 
                </li>                     
                <li class="nav-item"> 
                    <a class="nav-link" href="#"><?php _e( 'Link', 'travel_agency' ); ?></a> 
                </li>                     
                <li class="nav-item"> 
                    <a class="nav-link" href="#"><?php _e( 'Link', 'travel_agency' ); ?></a> 
                </li>                     
            </ul>                 
        </div>             
    </nav>
    <div class="container">
        <div class="row header">
            <div class="col-md-8">
                <h1 class="display-3 text-white"><?php _e( 'My Travel Agency', 'travel_agency' ); ?></h1> 
                <p class="lead text-white"><?php _e( 'Cras justo odio, dapibus ac facilisis in, egestas eget quam. Donec id elit non mi porta gravida at eget metus. Nullam id dolor id nibh ultricies vehicula ut id elit.', 'travel_agency' ); ?></p> 
            </div>
        </div>
        <div class="row">
            <div class="col-md-8 main-content">
                <div class="row">
                    <div class="col-md-12 content-section">
                        <h2><?php _e( 'About our trips', 'travel_agency' ); ?></h2> 
                        <p><?php _e( 'Cras justo odio, dapibus ac facilisis in, egestas eget quam. Donec id elit non mi porta gravida at eget metus. Nullam id dolor id nibh ultricies vehicula ut id elit.', 'travel_agency' ); ?></p> 
                    </div>
                </div>
                <div class="row">
                    <?php get_template_part( null ); ?>
                </div>
                <div class="row">
                    <div class="col-md-12 content-section ">
                        <h2><?php _e( 'Our advantages', 'travel_agency' ); ?></h2> 
                        <p><?php _e( 'Cras justo odio, dapibus ac facilisis in, egestas eget quam. Donec id elit non mi porta gravida at eget metus. Nullam id dolor id nibh ultricies vehicula ut id elit.', 'travel_agency' ); ?></p> 
                    </div>
                    <div class="col-md-12 content-section ">
                        <h2><?php _e( 'Contact Form', 'travel_agency' ); ?></h2> 
                        <p><?php _e( 'Cras justo odio, dapibus ac facilisis in, egestas eget quam. Donec id elit non mi porta gravida at eget metus. Nullam id dolor id nibh ultricies vehicula ut id elit.', 'travel_agency' ); ?></p>
                        <form>
                            <div class="form-group">
                                <label for="exampleInputEmail1">
                                    <?php _e( 'Email address', 'travel_agency' ); ?>
                                </label>
                                <input type="email" class="form-control" id="exampleInputEmail1" aria-describedby="emailHelp" placeholder="Enter email" />
                                <small id="emailHelp" class="form-text text-muted"><?php _e( 'We\'ll never share your email with anyone else.', 'travel_agency' ); ?></small>
                            </div>
                            <div class="form-group">
                                <label for="exampleFormControlSelect1">
                                    <?php _e( 'Example select', 'travel_agency' ); ?>
                                </label>
                                <select class="form-control" id="exampleFormControlSelect1">
                                    <option>
                                        <?php _e( '1', 'travel_agency' ); ?>
                                    </option>
                                    <option>
                                        <?php _e( '2', 'travel_agency' ); ?>
                                    </option>
                                    <option>
                                        <?php _e( '3', 'travel_agency' ); ?>
                                    </option>
                                    <option>
                                        <?php _e( '4', 'travel_agency' ); ?>
                                    </option>
                                    <option>
                                        <?php _e( '5', 'travel_agency' ); ?>
                                    </option>
                                </select>
                            </div>
                            <div class="form-group">
                                <label for="exampleFormControlTextarea1">
                                    <?php _e( 'Example textarea', 'travel_agency' ); ?>
                                </label>
                                <textarea class="form-control" id="exampleFormControlTextarea1" rows="3"></textarea>
                            </div>
                            <button type="submit" class="btn btn-dark">
                                <?php _e( 'Submit', 'travel_agency' ); ?>
                            </button>
                        </form>                             
                    </div>
                </div>                     
            </div>
        </div>
    </div>
    <!-- Bootstrap core JavaScript
================================================== -->
    <!-- Placed at the end of the document so the pages load faster -->
    <footer>
        <div class="container">
            <div class="row">
                <div class="col-md-8">
                    <hr />
                    <div class="row">
                        <div class="col-md-6 text-light">
                            <h3><?php _e( 'I hope this really works', 'travel_agency' ); ?></h3> 
                            <p><?php _e( 'Cras justo odio, dapibus ac facilisis in, egestas eget quam. Donec id elit non mi porta gravida at eget metus. Nullam id dolor id nibh ultricies vehicula ut id elit.', 'travel_agency' ); ?></p> 
                        </div>
                        <div class="col-md-6 text-light">
                            <h3><?php _e( '&lt; Like it says over there', 'travel_agency' ); ?></h3> 
                            <p><?php _e( 'Cras justo odio, dapibus ac facilisis in, egestas eget quam. Donec id elit non mi porta gravida at eget metus. Nullam id dolor id nibh ultricies vehicula ut id elit.', 'travel_agency' ); ?></p> 
                        </div>
                    </div>                         
                </div>
            </div>
        </div>
    </footer>        

<?php get_footer(); ?>